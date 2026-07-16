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
}
