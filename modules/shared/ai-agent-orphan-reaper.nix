{ config, lib, pkgs, ... }:

# Reaper for orphaned test-tool children inside an ai-* microvm.
#
# Motivating incident (21 June): vega's `npx vitest run` spawned ~187
# @cloudflare/vitest-pool-workers/workerd children. The vitest parent
# was OOM-killed, the workerd children re-parented to PID 1 and pinned
# RAM at 7.7/8GB + swap full for the whole microvm. Cascading OOM
# reaped multiple claude sessions; four tmux panes dropped to local
# bash on perdurabo.
#
# Design captured from codex consult (session 019e52f1-cf02-7c72,
# task #274):
#
#   - PLACEMENT: in-microvm. The guest has the best process/cgroup
#     view and can react before memory pressure cascades. Bosun
#     observes via journal; it does NOT own enforcement.
#   - HEURISTIC: cmdline allowlist (no plain `node` etc) AND orphaned
#     (PPID=1 OR session leader gone) AND age > grace seconds AND
#     belongs to the agent user slice.
#   - SAFETY: defaults to log-only / dry-run; SIGTERM before SIGKILL;
#     per-pattern exemptions and a protected-cwd regex are operator
#     escape hatches.
#   - SCOPE: ship as a shared module imported by every ai-* microvm.
#
# Module options under `my.orphanReaper.*`. Disabled by default; turn
# on per-vm.

let
  cfg = config.my.orphanReaper;

  # The reap script is plain bash + procfs. Keeps the moving parts
  # auditable: a future operator can read /usr/local/bin/... and
  # understand exactly which processes get touched.
  reapScript = pkgs.writeShellScript "ai-agent-orphan-reaper" ''
    set -u
    : "''${ORPHAN_REAPER_DRY_RUN:=${if cfg.dryRun then "1" else "0"}}"
    : "''${ORPHAN_REAPER_GRACE_SECS:=${toString cfg.graceSeconds}}"
    : "''${ORPHAN_REAPER_USER:=${cfg.user}}"

    # Allowlist of cmdline substrings. A process is only ever
    # considered for reap when one of these matches its argv. Never
    # matches a bare `node` — too easy to false-positive on dev
    # servers, postinstall hooks, debugger sessions.
    patterns=(${lib.concatMapStringsSep " " (p: "'${p}'") cfg.patterns})

    # Protected cwd / cmdline substrings. A process matching any of
    # these is skipped regardless of orphan status. Operator escape
    # hatch for long-running test workers that intentionally outlive
    # their parent.
    protected=(${lib.concatMapStringsSep " " (p: "'${p}'") cfg.protected})

    now=$(${pkgs.coreutils}/bin/date +%s)
    boot_secs=$(${pkgs.coreutils}/bin/awk '{print int($1)}' /proc/uptime)

    # emit one structured line per decision (warn or reap) so journald
    # consumers (resmon, dashboard #271) can ingest without parsing
    # free text.
    emit() {
      local kind="$1" pid="$2" rss="$3" age="$4" cmd="$5"
      printf '{"tag":"orphan-reaper","kind":"%s","pid":%s,"rss_kb":%s,"age_sec":%s,"cmd":%s,"dry_run":%s}\n' \
        "$kind" "$pid" "$rss" "$age" \
        "$(printf %s "$cmd" | ${pkgs.jq}/bin/jq -Rs .)" \
        "$ORPHAN_REAPER_DRY_RUN"
    }

    matches_any() {
      local needle="$1"; shift
      for p in "$@"; do
        case "$needle" in
          *"$p"*) return 0 ;;
        esac
      done
      return 1
    }

    for pid_dir in /proc/[0-9]*; do
      pid=''${pid_dir##*/}
      [ "$pid" = "1" ] && continue

      # cmdline: NUL-separated. Read once.
      cmdline=$(${pkgs.coreutils}/bin/tr '\0' ' ' < "$pid_dir/cmdline" 2>/dev/null) || continue
      [ -z "$cmdline" ] && continue

      matches_any "$cmdline" "''${patterns[@]}" || continue
      ! matches_any "$cmdline" "''${protected[@]}" || continue

      # status: extract Uid + PPid in one read.
      status=$(${pkgs.coreutils}/bin/cat "$pid_dir/status" 2>/dev/null) || continue
      uid=$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^Uid:[[:space:]]*\([0-9]*\).*/\1/p')
      ppid=$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^PPid:[[:space:]]*\([0-9]*\).*/\1/p')
      rss=$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^VmRSS:[[:space:]]*\([0-9]*\).*/\1/p')
      rss=''${rss:-0}

      # Constrain to the configured agent user. System services are
      # never in scope.
      target_uid=$(${pkgs.coreutils}/bin/id -u "$ORPHAN_REAPER_USER" 2>/dev/null) || continue
      [ "$uid" = "$target_uid" ] || continue

      # Orphan signal: PPid=1 is the cheapest indicator. Real session
      # leader gone is a stronger signal but requires walking the
      # session group; PPid=1 + allowlist is acceptably conservative.
      [ "$ppid" = "1" ] || continue

      # Age: stat file's first modification — sufficient proxy for
      # process start within the grace window. /proc/<pid>/stat field
      # 22 is starttime in jiffies since boot.
      start_jiffies=$(${pkgs.coreutils}/bin/awk '{print $22}' "$pid_dir/stat" 2>/dev/null) || continue
      hz=${toString cfg.clockHz}
      start_secs=$(( boot_secs - (start_jiffies / hz) ))
      age=$(( now - start_secs ))
      [ "$age" -ge "$ORPHAN_REAPER_GRACE_SECS" ] || continue

      if [ "$ORPHAN_REAPER_DRY_RUN" = "1" ]; then
        emit "warn" "$pid" "$rss" "$age" "$cmdline"
        continue
      fi

      emit "reap-term" "$pid" "$rss" "$age" "$cmdline"
      kill -TERM "$pid" 2>/dev/null || true
      ${pkgs.coreutils}/bin/sleep 5
      if [ -d "$pid_dir" ]; then
        emit "reap-kill" "$pid" "$rss" "$age" "$cmdline"
        kill -KILL "$pid" 2>/dev/null || true
      fi
    done
  '';
in
{
  options.my.orphanReaper = {
    enable = lib.mkEnableOption "in-microvm reaper for orphaned test/tool children";

    dryRun = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        When true (the default), the reaper only logs decisions to
        journald and never sends signals. Flip to false per-microvm
        once the operator has watched a week's worth of warn-only
        output and confirmed no false positives.
      '';
    };

    patterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "vitest-pool-workers"
        "@cloudflare/workerd"
        "playwright"
        "chromium-browser"
      ];
      description = ''
        cmdline substrings that mark a process as eligible for reap.
        A process is only considered when at least one entry matches
        its argv. Keep this list narrow — adding bare `node` or
        `python` would risk killing dev servers and debugger
        sessions.
      '';
    };

    protected = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "tailscale" "sshd" "systemd" ];
      description = ''
        Substrings that exempt a process from reap regardless of
        orphan status. Operator escape hatch for long-running
        children that intentionally outlive their parent (e.g. a
        debugger attached to a test worker).
      '';
    };

    graceSeconds = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = ''
        Minimum age in seconds before an orphan is eligible for reap.
        90s is the lower bound codex recommended (60-120s) to avoid
        catching processes mid-handoff.
      '';
    };

    intervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = ''
        How often the systemd timer fires the reaper. 60s strikes the
        balance between responding before memory cascades and not
        burning CPU walking /proc constantly.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "agent";
      description = ''
        UNIX user whose processes the reaper considers. System
        services owned by root are never in scope.
      '';
    };

    clockHz = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = ''
        Kernel CLK_TCK value used to convert /proc/<pid>/stat's
        starttime jiffies to seconds. 100 is the standard kernel
        default; override only if the guest kernel reports
        differently via `getconf CLK_TCK`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ai-agent-orphan-reaper = {
      description = "Reap orphaned test/tool children inside the ai-agent guest";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${reapScript}";
        # Reaper itself is small and quick; no need to run as the
        # agent user — it needs to read /proc for everyone and send
        # signals to the agent's processes.
        User = "root";
        Nice = 10;
        IOSchedulingClass = "idle";
        # Cap one run; the timer handles cadence.
        TimeoutStartSec = "30s";
      };
    };

    systemd.timers.ai-agent-orphan-reaper = {
      description = "Periodically reap orphaned test/tool children";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "60s";
        OnUnitActiveSec = "${toString cfg.intervalSeconds}s";
        AccuracySec = "5s";
      };
    };
  };
}
