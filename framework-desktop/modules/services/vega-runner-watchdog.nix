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

{
  systemd.services.vega-runner-watchdog = {
    description = "Recover the vega-runner container if it has fallen over";
    serviceConfig.Type = "oneshot";
    path = [ config.virtualisation.docker.package pkgs.coreutils ];
    script = ''
      name=vega-runner

      # Only recover a container that exists; never create one.
      docker inspect "$name" >/dev/null 2>&1 || {
        echo "container $name does not exist; nothing to recover" >&2
        exit 0
      }

      running() { docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null; }
      [ "$(running)" = "true" ] && exit 0

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
      img=$(docker inspect -f '{{.Image}}' "$name" 2>/dev/null)
      vol=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/nix"}}{{.Name}}{{end}}{{end}}' "$name" 2>/dev/null)
      echo "$name still down (exit=$code); reseeding /nix volume $vol from image" >&2
      if [ -n "$img" ] && [ -n "$vol" ]; then
        docker run --rm --entrypoint /bin/sh -v "$vol":/vol "$img" \
          -c 'cp -an /nix/store/. /vol/store/ 2>/dev/null' || true
        docker start "$name" >/dev/null 2>&1 || true
        sleep 3
        if [ "$(running)" = "true" ]; then
          echo "$name recovered by reseed+start" >&2
        else
          echo "$name recovery FAILED; needs a human" >&2
        fi
      else
        echo "could not resolve image/volume for $name; recovery skipped" >&2
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
  # nix tooling as it runs, because nothing in the container roots it (the
  # same mechanism the recover service above documents). So this reseeds
  # the tooling from the image first — additive cp -an, so it only restores
  # what a prior GC removed — and then collects. It skips while a job is in
  # flight so it never races a live build.
  systemd.services.vega-runner-nix-gc = {
    description = "Garbage-collect the vega-runner container's nix store";
    serviceConfig.Type = "oneshot";
    path = [ config.virtualisation.docker.package pkgs.coreutils pkgs.gnugrep ];
    script = ''
      name=vega-runner

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
      # can run. Additive; a no-op when the tooling is already present.
      vol=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/nix"}}{{.Name}}{{end}}{{end}}' "$name" 2>/dev/null)
      img=$(docker inspect -f '{{.Image}}' "$name" 2>/dev/null)
      if [ -n "$vol" ] && [ -n "$img" ]; then
        docker run --rm --entrypoint /bin/sh -v "$vol":/vol "$img" \
          -c 'cp -an /nix/store/. /vol/store/ 2>/dev/null' || true
      fi

      echo "$name idle; collecting dead store paths. df /nix before:" >&2
      docker exec "$name" df -h /nix 2>/dev/null | tail -1 >&2
      # sh -lc so nix-collect-garbage resolves via the container's nix
      # profile PATH; a bare exec uses a minimal PATH without it.
      docker exec "$name" sh -lc nix-collect-garbage 2>&1 | tail -3 \
        || echo "GC in $name returned non-zero" >&2
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
