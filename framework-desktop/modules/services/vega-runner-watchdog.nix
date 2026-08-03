# The GitHub self-hosted runner `vega-perdurabo` runs as the docker
# container `vega-runner` (image ghcr.io/ad-astra-computing/vega-builder).
# Its entrypoint is a symlink into /nix, and the container's /nix is a
# named volume. The container's own periodic nix GC can collect the
# entrypoint's store closure, leaving a dangling symlink; the container
# then exits 127 on every start, so docker's restart=unless-stopped
# cannot recover it and the runner sits offline until someone notices.
#
# This watchdog checks the container every few minutes and recovers it:
# a plain start first, and if that still leaves it down (the 127 case),
# it reseeds the missing store paths back into the /nix volume from the
# container's own image, then starts again. It never creates the
# container, so a genuinely absent runner is left for a human.
{ config, pkgs, lib, ... }:

let
  # Shared shell helpers for both units below.
  #
  # The reseed is a plain recursive copy out of the image, so the restored
  # paths exist on disk but have no entry in the container's nix database.
  # Nothing here can change that: the image ships the files, not the
  # database rows that would make them valid store paths. Everything below
  # is written around that fact.
  helpers = ''
    name=vega-runner

    # The path of the runner's run.sh, read from the live process rather
    # than hardcoded, so a runner version bump does not silently turn
    # these checks into no-ops.
    runner_script() {
      docker exec "$name" /bin/sh -c \
        'tr "\0" "\n" < /proc/1/cmdline | grep -m1 "/run\.sh$"' 2>/dev/null
    }

    # A running container is not necessarily a working one, which is the
    # whole reason this check exists. The listener keeps its own deleted
    # files open, so after a GC removes the runner's store path the
    # container stays up and keeps ACCEPTING jobs it can no longer run: it
    # cannot spawn Runner.Worker, so each job dies at GitHub's ten-minute
    # no-communication timeout. That is worse than being down, because an
    # offline runner leaves jobs queued instead of failing them.
    runner_binaries_present() {
      s=$(runner_script)
      [ -n "$s" ] || return 1
      docker exec "$name" /bin/sh -c \
        "[ -e '$s' ] && [ -e \"\$(dirname '$s')/Runner.Worker\" ]" >/dev/null 2>&1
    }

    # Additive restore from the container's own image; a no-op for paths
    # that are already there.
    reseed() {
      vol=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/nix"}}{{.Name}}{{end}}{{end}}' "$name" 2>/dev/null)
      img=$(docker inspect -f '{{.Image}}' "$name" 2>/dev/null)
      if [ -z "$vol" ] || [ -z "$img" ]; then
        echo "could not resolve image/volume for $name; reseed skipped" >&2
        return 1
      fi
      docker run --rm --entrypoint /bin/sh -v "$vol":/vol "$img" \
        -c 'cp -an /nix/store/. /vol/store/ 2>/dev/null' || true
    }
  '';
in
{
  systemd.services.vega-runner-watchdog = {
    description = "Recover the vega-runner container if it has fallen over";
    serviceConfig.Type = "oneshot";
    path = [ config.virtualisation.docker.package pkgs.coreutils pkgs.gnugrep ];
    script = helpers + ''
      # Only recover a container that exists; never create one.
      docker inspect "$name" >/dev/null 2>&1 || {
        echo "container $name does not exist; nothing to recover" >&2
        exit 0
      }

      running() { docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null; }

      if [ "$(running)" = "true" ]; then
        runner_binaries_present && exit 0

        # Up but gutted. Restoring the files is necessary but not
        # sufficient: the listener is a .NET process that caches an
        # assembly-binding failure for its own lifetime, so once it has
        # tried to dispatch a worker while the runtime was missing it
        # keeps failing with the same FileNotFoundException even after
        # the files come back. It has to be restarted to forget that.
        echo "$name is running but its runner binaries are gone; reseeding" >&2
        reseed || exit 0
        if ! runner_binaries_present; then
          echo "$name reseed did not restore its binaries; needs a human" >&2
          exit 0
        fi
        echo "$name binaries restored; restarting so it drops its cached load failures" >&2
        docker restart "$name" >/dev/null 2>&1 || true
        sleep 3
        [ "$(running)" = "true" ] \
          && echo "$name recovered by reseed+restart" >&2 \
          || echo "$name did not come back after restart; needs a human" >&2
        exit 0
      fi

      echo "$name is not running; trying a plain start" >&2
      docker start "$name" >/dev/null 2>&1 || true
      sleep 3
      if [ "$(running)" = "true" ]; then
        echo "$name recovered by start" >&2
        exit 0
      fi

      # Still down: the entrypoint symlink is almost certainly dangling
      # because the volume's nix GC removed its store path. Reseed the
      # image's store paths back into the /nix volume (additive) so the
      # entrypoint resolves, then start again.
      code=$(docker inspect -f '{{.State.ExitCode}}' "$name" 2>/dev/null)
      echo "$name still down (exit=$code); reseeding /nix volume from image" >&2
      reseed || exit 0
      docker start "$name" >/dev/null 2>&1 || true
      sleep 3
      if [ "$(running)" = "true" ]; then
        echo "$name recovered by reseed+start" >&2
      else
        echo "$name recovery FAILED; needs a human" >&2
      fi
    '';
  };

  systemd.timers.vega-runner-watchdog = {
    description = "Run vega-runner-watchdog every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      AccuracySec = "30s";
    };
  };

  # The container's /nix is a named volume that grows with every CI build
  # and its in-container GC does not keep up: on 20 July the accumulated
  # store filled the host root FS to 100%. This collects the container's
  # dead store paths on a schedule so the volume stays bounded.
  #
  # nix-collect-garbage inside the container deletes the container's own
  # nix tooling and the runner itself as it runs. Rooting them does not
  # help: they were restored by a file copy out of the image, so they are
  # not valid store paths, and nix skips a gcroot pointing at one. So this
  # reseeds around the collection rather than trying to protect anything
  # from it — once before, so nix-collect-garbage has tooling to run with,
  # and again after, to put back what it took. Without that second reseed
  # the GC leaves the runner unable to spawn a worker until a human
  # notices. It skips while a job is in flight so it never races a build.
  systemd.services.vega-runner-nix-gc = {
    description = "Garbage-collect the vega-runner container's nix store";
    serviceConfig.Type = "oneshot";
    path = [ config.virtualisation.docker.package pkgs.coreutils pkgs.gnugrep ];
    script = helpers + ''
      docker inspect "$name" >/dev/null 2>&1 || {
        echo "container $name does not exist; skipping GC" >&2
        exit 0
      }
      [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null)" = "true" ] || {
        echo "$name not running; skipping GC" >&2
        exit 0
      }

      # A job in flight spawns Runner.Worker; leave the store alone until
      # it finishes so GC never contends with a live build.
      if docker top "$name" 2>/dev/null | grep -q Runner.Worker; then
        echo "$name has a job in flight; skipping GC this cycle" >&2
        exit 0
      fi

      # Restore the nix tooling a prior GC removed, so nix-collect-garbage
      # can run at all.
      reseed || exit 0

      echo "$name idle; collecting dead store paths. df /nix before:" >&2
      docker exec "$name" df -h /nix 2>/dev/null | tail -1 >&2
      # sh -lc so nix-collect-garbage resolves via the container's nix
      # profile PATH; a bare exec uses a minimal PATH without it.
      docker exec "$name" sh -lc nix-collect-garbage 2>&1 | tail -3 \
        || echo "GC in $name returned non-zero" >&2

      # Put back what the collection just took. This is the step whose
      # absence left the runner accepting jobs it could not execute.
      reseed || exit 0
      if runner_binaries_present; then
        echo "$name runner binaries present after GC" >&2
      else
        echo "$name runner binaries MISSING after GC reseed; needs a human" >&2
      fi
      docker exec "$name" df -h /nix 2>/dev/null | tail -1 >&2
    '';
  };

  systemd.timers.vega-runner-nix-gc = {
    description = "Garbage-collect the vega-runner nix store daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
