{ config, lib, pkgs, ... }:

# Shared guest NixOS module used by both microvm-based (perdurabo) and
# systemd-nspawn-based (congo) AI agent sandboxes. Defines the unprivileged
# agent user, the CLI binary, and the loopback sshd the host uses to shell in.
#
# Options:
#   my.aiAgent.name     = string (e.g. "claude")
#   my.aiAgent.packages = list of CLI derivations
#   my.aiAgent.sshPort  = int, loopback port for host alias to connect to
#   my.aiAgent.hostPublicKeys = list of SSH pubkeys authorized to shell in

let
  cfg = config.my.aiAgent;

  # Shared OSC-tint helpers (background + tab + window title), the same
  # snippet the perdurabo host uses. Sourced here so a `claude --yolo`
  # invoked INSIDE the microvm (after `ssh ai-claude` already happened)
  # still emits the red banner; otherwise the host wrapper only fires
  # when the operator types `claude` at the local shell, and tmux send-
  # keys or direct ssh sessions skip the tint entirely.
  yoloHelpers = (import ./yolo-agent-wrappers.nix { inherit lib; }).shellSnippet;

  # ~/peers is the shared parent ai-agents dir. A "_inbox" subdir there
  # acts as a message queue between the three guests: each ask writes
  # _inbox/<to>/<id>.json, the recipient's watcher invokes its local
  # CLI and drops _inbox/<from>/<id>.response.json.
  inboxDir = "/home/agent/peers/_inbox";

  askPeer = pkgs.writeShellScriptBin "ask-peer" ''
    set -eu
    share_context=0
    if [ "''${1:-}" = "--share-context" ]; then
      share_context=1; shift
    fi
    if [ $# -lt 2 ]; then
      echo "usage: ask-peer [--share-context] <peer> <prompt...>" >&2
      echo "       peers: claude codex antigravity (+ any model-tier alias, e.g. fable)" >&2
      echo "       ask-peer <peer> 'resume:<session-id> <prompt...>'" >&2
      exit 2
    fi
    to=$1; shift
    prompt="$*"
    self=$(${pkgs.inetutils}/bin/hostname | sed 's/^ai-//')

    ${pkgs.coreutils}/bin/mkdir -p "${inboxDir}/$to" "${inboxDir}/$self"

    id=$(${pkgs.util-linux}/bin/uuidgen)
    req="${inboxDir}/$to/$id.json"
    resp="${inboxDir}/$self/$id.response.json"

    # Each section is byte-bounded; the recipient prepends the whole bundle
    # to the prompt before invoking its CLI.
    context_json=null
    if [ "$share_context" = "1" ]; then
      cwd=$(${pkgs.coreutils}/bin/pwd)
      branch=$(${pkgs.git}/bin/git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
      status=$(${pkgs.git}/bin/git -C "$cwd" status --short 2>/dev/null | ${pkgs.coreutils}/bin/head -c 4096 || true)
      diffstat=$(${pkgs.git}/bin/git -C "$cwd" diff --stat 2>/dev/null | ${pkgs.coreutils}/bin/head -c 2048 || true)
      log=$(${pkgs.git}/bin/git -C "$cwd" log -5 --oneline 2>/dev/null || true)
      context_json=$(${pkgs.jq}/bin/jq -n \
        --arg cwd "$cwd" --arg branch "$branch" --arg status "$status" \
        --arg diffstat "$diffstat" --arg log "$log" \
        '{cwd:$cwd, branch:$branch, git_status:$status, git_diff_stat:$diffstat, recent_commits:$log}')
    fi

    ${pkgs.jq}/bin/jq -n \
      --arg id "$id" --arg from "$self" --arg to "$to" --arg p "$prompt" \
      --argjson context "$context_json" \
      '{id:$id, from:$from, to:$to, prompt:$p, context:$context, created_at: (now|todate)}' \
      > "$req.tmp"
    ${pkgs.coreutils}/bin/mv "$req.tmp" "$req"

    for _ in $(seq 1 300); do
      if [ -f "$resp" ]; then
        ${pkgs.jq}/bin/jq -r '.response' "$resp"
        ${pkgs.coreutils}/bin/rm -f "$resp"
        exit 0
      fi
      sleep 1
    done
    echo "ask-peer: timeout waiting for $to" >&2
    exit 1
  '';

  inboxWatcher = pkgs.writeShellScriptBin "ai-peer-inbox-watcher" ''
    set -u
    self=$(${pkgs.inetutils}/bin/hostname | sed 's/^ai-//')

    # Inbox names this host answers: its own name, served with the CLI's
    # default model, plus any model-tier aliases from config, each served
    # by pinning the CLI to that model. A new model tier becomes a
    # reachable peer via one config string, not a broker edit.
    aliases="${lib.concatStringsSep " " cfg.modelAliases}"

    # A prompt prefixed with "resume:<session-id> ..." continues that
    # recorded session instead of starting a fresh one. antigravity-cli
    # uses --continue for the most-recent session; per-id resume is via
    # --conversation, mirrored here. invoke takes <model> <session-id>
    # <prompt>; an empty model means the CLI's own default.
    case "$self" in
      claude) invoke() {
        margs=""; [ -n "$1" ] && margs="--model $1"
        if [ -n "$2" ]; then claude $margs --resume "$2" -p "$3" 2>&1
        else                  claude $margs -p "$3" 2>&1
        fi
      } ;;
      codex)  invoke() {
        # /home/agent isn't a git repo; bypass flag skips approval prompts
        # that would hang a non-interactive exec. --all so sessions
        # recorded in any cwd remain resumable. codex exposes no model-tier
        # alias here, so the model arg ($1) is unused.
        FLAGS="--dangerously-bypass-approvals-and-sandbox --skip-git-repo-check"
        if [ -n "$2" ]; then codex exec $FLAGS resume --all "$2" "$3" 2>&1
        else                  codex exec $FLAGS "$3" 2>&1
        fi
      } ;;
      antigravity) invoke() {
        if [ -n "$2" ]; then agy --conversation "$2" -p "$3" 2>&1
        else                  agy -p "$3" 2>&1
        fi
      } ;;
      *) echo "unknown agent $self" >&2; exit 1 ;;
    esac

    # process <request-file> <inbox-name> <model>
    process() {
      req=$1; iam=$2; model=$3
      [ -f "$req" ] || return
      case "$req" in *.response.json|*.processing) return ;; esac

      processing="''${req%.json}.processing"
      ${pkgs.coreutils}/bin/mv "$req" "$processing" 2>/dev/null || return

      id=$(${pkgs.jq}/bin/jq -r '.id' "$processing")
      from=$(${pkgs.jq}/bin/jq -r '.from' "$processing")
      prompt=$(${pkgs.jq}/bin/jq -r '.prompt' "$processing")
      has_context=$(${pkgs.jq}/bin/jq -r '.context != null' "$processing" 2>/dev/null || echo false)

      sid=""
      case "$prompt" in
        resume:*' '*)
          rest=''${prompt#resume:}
          sid=''${rest%% *}
          prompt=''${rest#* }
          ;;
      esac

      # Empty git sections are dropped from the preamble.
      if [ "$has_context" = "true" ]; then
        preamble=$(${pkgs.jq}/bin/jq -r '
          .context as $c |
          "## Shared context from " + .from + "\n\n" +
          "**cwd**: " + ($c.cwd // "(unknown)") + "\n" +
          (if ($c.branch // "") != "" then "**branch**: " + $c.branch + "\n" else "" end) +
          (if ($c.git_status // "") != "" then "\n### git status\n```\n" + $c.git_status + "\n```\n" else "" end) +
          (if ($c.git_diff_stat // "") != "" then "\n### diff stat\n```\n" + $c.git_diff_stat + "\n```\n" else "" end) +
          (if ($c.recent_commits // "") != "" then "\n### recent commits\n```\n" + $c.recent_commits + "\n```\n" else "" end) +
          "\n---\n\n"
        ' "$processing")
        prompt="''${preamble}''${prompt}"
      fi

      response=$(invoke "$model" "$sid" "$prompt" || true)

      out=${inboxDir}/$from
      ${pkgs.coreutils}/bin/mkdir -p "$out"
      ${pkgs.jq}/bin/jq -n \
        --arg id "$id" --arg from "$iam" --arg to "$from" --arg r "$response" \
        '{id:$id, from:$from, to:$to, response:$r, created_at: (now|todate)}' \
        > "$out/$id.response.json.tmp"
      ${pkgs.coreutils}/bin/mv "$out/$id.response.json.tmp" "$out/$id.response.json"

      ${pkgs.coreutils}/bin/rm -f "$processing"
    }

    # Poll each served inbox. inotify doesn't fire when the writer is on
    # the other side of a virtiofs (perdurabo) or bind mount (congo), so
    # cross-vm asks would queue forever waiting for an event that never
    # arrives. serve <inbox-name> <model>.
    serve() {
      d=${inboxDir}/$1
      ${pkgs.coreutils}/bin/mkdir -p "$d"
      for f in "$d"/*.json; do
        [ -e "$f" ] || continue
        process "$f" "$1" "$2"
      done
    }

    while :; do
      serve "$self" ""
      for a in $aliases; do serve "$a" "$a"; done
      sleep 2
    done
  '';
in
{
  options.my.aiAgent = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Short name for this agent (claude, codex, antigravity).";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "CLI packages to install inside the guest.";
    };
    sshPort = lib.mkOption {
      type = lib.types.port;
      description = "Loopback port sshd listens on inside the guest.";
    };
    hostPublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys authorized to shell in as the agent user.";
    };
    envFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional systemd-style environment file (KEY=VAL per line, no
        `export`) loaded by the ai-peer-inbox-watcher service. Used to
        give the watcher API keys the agent CLI needs when invoked
        non-interactively (the service is neither login nor interactive,
        so ~/.bashrc and ~/.profile are not sourced).
      '';
    };
    modelAliases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Extra peer inbox names this agent answers by invoking its CLI
        pinned to that name as a model tier. A message to `ask-peer
        <alias>` lands in the alias inbox and this host replies with
        `<cli> --model <alias>`, so a new model tier is reachable as a
        peer via one config string rather than a broker edit. Only the
        claude backend applies the model pin today.
      '';
    };
  };

  config = {
    users.mutableUsers = false;
    # Guest is only reachable via sshd with the host's pubkey. No interactive
    # login as root or any other user, so silence the "no password set" assert.
    users.allowNoPasswordLogin = true;

    users.users.agent = {
      isNormalUser = true;
      uid = 1000;
      home = "/home/agent";
      createHome = true;
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = cfg.hostPublicKeys;
    };

    users.groups.agent.gid = 1000;

    environment.systemPackages = cfg.packages ++ (with pkgs; [
      git
      curl
      jq
      ripgrep
      nodejs
      openssh
      gnupg
      gh
      # Editor + pager + modern coreutils
      vim
      less
      bat
      fd
      # JS / Cloudflare Workers stack
      wrangler
      bun
      flyctl
      direnv
      gnumake
      delta
      yq-go
      sqlite
      # Nix repo work
      agenix-cli
      nixpkgs-fmt
      alejandra
      # Shell quality-of-life
      httpie
      tldr
      ripgrep-all
      # Peer messaging
      askPeer
      # SDKs the agents reach for most often; available without nix-shell.
      (python3.withPackages (ps: with ps; [ anthropic openai ]))
    ]);

    systemd.services.ai-peer-inbox-watcher = {
      description = "Watch peer inbox for messages from other AI agents";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = cfg.packages;
      serviceConfig = {
        Type = "simple";
        User = "agent";
        Group = "agent";
        ExecStart = "${inboxWatcher}/bin/ai-peer-inbox-watcher";
        Restart = "always";
        RestartSec = "5s";
      } // lib.optionalAttrs (cfg.envFile != null) {
        EnvironmentFile = cfg.envFile;
      };
    };

    # Required to run claude-code (Bun standalone) without patching it -
    # the binary's PT_INTERP is /lib64/ld-linux-x86-64.so.2 and patchelf
    # corrupts its embedded JS payload.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
      ];
    };

    # nix-shell -p X resolves X against the same nixpkgs the guest was
    # built from; pairs with the writable /nix/store overlay so packages
    # can actually materialize at runtime.
    nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

    # Stop claude-code's self-updater from downloading a parallel binary
    # into ~/.local/share/claude. The overlay version is bumped by
    # .github/workflows/update-claude-code.yml.
    environment.variables = {
      DISABLE_AUTOUPDATER = "1";
    };

    # Shadow `claude`/`codex`/`antigravity` in the guest's interactive
    # shell with a function that fires the OSC red-tint when invoked
    # with a permission-bypass flag. Only the function matching
    # cfg.name is installed so the wrapper doesn't shadow CLIs that
    # aren't really available in this microvm. antigravity-cli ships
    # as `agy`; the wrapper keeps the human-friendly label and aliases
    # `agy` to the antigravity function so both names hit the tint.
    programs.bash.interactiveShellInit = ''
      ${yoloHelpers}
    '' + (lib.optionalString (cfg.name == "claude") ''
      claude() { __yolo_wrap claude "command claude" "$@"; }
    '') + (lib.optionalString (cfg.name == "codex") ''
      codex()  { __yolo_wrap codex  "command codex"  "$@"; }
    '') + (lib.optionalString (cfg.name == "antigravity") ''
      antigravity() { __yolo_wrap antigravity "command agy" "$@"; }
      agy()         { antigravity "$@"; }
    '');

    # claude-code still nags "Native installation exists but ~/.local/bin
    # is not in your PATH" on every startup even with the autoupdater off.
    # Putting the dir on PATH satisfies the check; it stays empty because
    # the autoupdater can't write to it.
    environment.sessionVariables = {
      PATH = [ "$HOME/.local/bin" ];
    };

    # Per-agent memory files documenting the local `ask-peer` command
    # so the agent knows it exists and how to use it (without this,
    # the binary is on PATH but the agent never calls it). One source
    # of truth in /etc, symlinked into each agent's per-user config
    # dir on every rebuild via systemd-tmpfiles. Only the file
    # matching the running agent's CLI is read; the other two are
    # harmless overhead.
    environment.etc."ai-agent/peer-doc.md".text = ''
      # Peer agents

      You can consult the codex or antigravity agent running in a sibling
      microvm via the `ask-peer` command:

          ask-peer <peer> "<prompt>"
          ask-peer <peer> "resume:<session-id> <prompt>"
          ask-peer --share-context <peer> "<prompt>"

      A `<peer>` is a sibling agent (`claude`, `codex`, `antigravity`) or
      a model-tier alias one of them answers (for example `fable`, served
      by claude as `claude --model fable`).

      The call blocks until the peer responds (default 5min timeout). Use it
      when you need a second opinion, a different model's reasoning, or to
      continue a recorded session on another agent.

      The `--share-context` flag attaches a snapshot of your current working
      state (cwd, git branch, `git status --short`, `git diff --stat`, last
      5 commits) to the prompt. The peer sees this as a markdown preamble.
      Use it when the peer needs to reason about the code you're editing.
      Otherwise leave it off to keep the prompt short.

      The peer bus is a JSON inbox at `~/peers/_inbox/<to>/`. Do not write to
      it directly — always use `ask-peer`. The inbox watcher
      (`ai-peer-inbox-watcher.service`) dispatches incoming asks to the
      local CLI and writes the response back.
    '';

    systemd.tmpfiles.rules = [
      "d /home/agent/.claude       0700 agent users -"
      "d /home/agent/.codex        0700 agent users -"
      "d /home/agent/.antigravity  0700 agent users -"
      "L+ /home/agent/.claude/CLAUDE.md            - - - - /etc/ai-agent/peer-doc.md"
      "L+ /home/agent/.codex/AGENTS.md             - - - - /etc/ai-agent/peer-doc.md"
      "L+ /home/agent/.antigravity/ANTIGRAVITY.md  - - - - /etc/ai-agent/peer-doc.md"
    ];

    # OpenPGP signing with the key in ~/.gnupg is the default. SSH signing
    # is opt-in per-invocation when the host's ssh-agent is forwarded:
    #   git -c gpg.format=ssh -c user.signingkey=~/.ssh/signing-key.pub \
    #       commit -S -m ...
    environment.etc."gitconfig".text = ''
      [user]
        name = Jason Odoom
        email = jason@adastracomputing.com
        signingkey = A46573671D50E3D8
      [commit]
        gpgsign = true
      [tag]
        gpgsign = true
      [core]
        # Repo hooks are nix-store-pinned to whichever host ran
        # pre-commit install, so their shebangs are unusable here. Point
        # hooksPath at an empty dir to skip them; run pre-commit manually
        # before opening a PR.
        hooksPath = /var/empty
      [url "ssh://git@perdurabo.ussuri-elevator.ts.net:2222/"]
        insteadOf = git@perdurabo.ussuri-elevator.ts.net:
    '';

    services.openssh = {
      enable = true;
      ports = [ cfg.sshPort ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      listenAddresses = [
        { addr = "0.0.0.0"; port = cfg.sshPort; }
      ];
      # Persist sshd host keys on a bind-mounted path so they survive
      # VM/container rebuilds and clients don't see host-key-changed warnings.
      hostKeys = [
        { path = "/var/lib/sshd-hostkeys/ssh_host_ed25519_key"; type = "ed25519"; }
        { path = "/var/lib/sshd-hostkeys/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
      ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.sshPort ];

    time.timeZone = "UTC";

    # Each agent guest carries its own /nix store. Without periodic
    # GC the guest's store keeps every old generation forever, and
    # since the host can't see inside the guest store, host-level
    # GC won't help. Weekly is plenty for a sandbox that only gets
    # nixos-rebuild touches. auto-optimise-store can't be enabled
    # here because microvm.writableStoreOverlay isn't compatible
    # with it.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
