{ config, pkgs, lib, inputs, ... }:

let
  forgejoUrl = "https://perdurabo.ussuri-elevator.ts.net";
  stateDir = "/var/lib/microvms/forgejo-runner";
in
{
  boot.kernelModules = [ "vhost_vsock" ];

  age.secrets = {
    forgejo-runner-token = {
      file = ../../secrets/forgejo-runner-token.age;
      mode = "0400";
      owner = "microvm";
      group = "kvm";
    };
    forgejo-runner-tailscale-authkey = {
      file = ../../secrets/forgejo-runner-tailscale-authkey.age;
      mode = "0400";
      owner = "microvm";
      group = "kvm";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir}         0750 microvm kvm -"
    "d ${stateDir}/state   0750 microvm kvm -"
    "d ${stateDir}/secrets 0750 microvm kvm -"
  ];

  microvm.vms.forgejo-runner = {
    specialArgs = { inherit inputs; };

    config = { config, pkgs, lib, inputs, ... }: {
      imports = [ inputs.microvm.nixosModules.microvm ];

      system.stateVersion = "25.11";
      networking.hostName = "perdurabo-ci";
      time.timeZone = "UTC";

      microvm = {
        hypervisor = "qemu";
        vcpu = 4;
        mem = 8192;
        balloon = true;
        vsock.cid = 42;

        interfaces = [{
          type = "user";
          id = "qemu";
          mac = "02:00:00:00:0c:01";
        }];

        volumes = [
          {
            mountPoint = "/var/lib/tailscale";
            image = "${stateDir}/tailscale.img";
            size = 256;
            fsType = "ext4";
          }
          {
            mountPoint = "/var/lib/containers";
            image = "${stateDir}/containers.img";
            size = 32768;
            fsType = "ext4";
          }
        ];

        shares = [
          {
            source = "${stateDir}/state";
            mountPoint = "/var/lib/runner";
            tag = "runner-state";
            proto = "virtiofs";
          }
          {
            source = "${stateDir}/secrets";
            mountPoint = "/run/host-secrets";
            tag = "runner-secrets";
            proto = "virtiofs";
          }
        ];
      };

      services.tailscale = {
        enable = true;
        authKeyFile = "/run/host-secrets/tailscale-authkey";
        extraUpFlags = [ "--ssh" "--hostname=perdurabo-ci" ];
      };

      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        dockerCompat = true;
        autoPrune = {
          enable = true;
          flags = [ "--all" ];
          dates = "weekly";
        };
      };

      services.gitea-actions-runner.instances.aer = {
        enable = true;
        name = "perdurabo-ci";
        url = forgejoUrl;
        tokenFile = "/run/host-secrets/runner-token";
        labels = [
          "nixos-podman:docker://node:20-bookworm"
          "ubuntu-latest:docker://node:20-bookworm"
        ];
        settings = {
          container = {
            # Bridge networking: jobs cannot reach host-only services
            # directly. act_runner still bind-mounts /var/run/docker.sock
            # into the job container so testcontainers works.
            network = "bridge";
            privileged = false;
            options = "-e DOCKER_HOST=unix:///var/run/docker.sock";
          };
          runner.capacity = 1;
          # I rewrite `uses: foo/bar@v1` to https://github.com/foo/bar so
          # third-party actions resolve. The default points at
          # data.forgejo.org which only mirrors forgejo's own actions and
          # 404s everything else.
          runner.default_actions_url = "https://github.com";
        };
      };

      networking.firewall.enable = true;
      networking.firewall.trustedInterfaces = [ "tailscale0" ];

      systemd.services.vm-diag = {
        description = "Dump runtime diagnostics to shared state dir";
        after = [ "tailscaled-autoconnect.service" "gitea-actions-runner-aer.service" ];
        wants = [ "tailscaled-autoconnect.service" "gitea-actions-runner-aer.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ tailscale coreutils systemd ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set +e
          out=/var/lib/runner/diag.txt
          {
            date -u
            echo "=== hostname ==="
            hostname
            echo "=== /dev/net/tun ==="
            ls -la /dev/net/tun 2>&1
            echo "=== tailscale status ==="
            tailscale status 2>&1 || true
            echo "=== tailscaled-autoconnect logs ==="
            journalctl -u tailscaled-autoconnect --no-pager -n 60 2>&1 || true
            echo "=== tailscaled logs ==="
            journalctl -u tailscaled --no-pager -n 60 2>&1 || true
            echo "=== gitea-actions-runner-aer logs ==="
            journalctl -u gitea-actions-runner-aer --no-pager -n 120 2>&1 || true
            echo "=== secret sizes ==="
            ls -la /run/host-secrets 2>&1
          } > "$out" 2>&1
          chmod 0644 "$out"
        '';
      };
    };
  };

  systemd.services."microvm@forgejo-runner" = {
    preStart = ''
      umask 0177
      printf 'TOKEN=%s\n' "$(tr -d '\r\n' < ${config.age.secrets.forgejo-runner-token.path})" \
        > ${stateDir}/secrets/runner-token
      chown microvm:kvm ${stateDir}/secrets/runner-token
      chmod 0444 ${stateDir}/secrets/runner-token
      install -m 0400 -o microvm -g kvm \
        ${config.age.secrets.forgejo-runner-tailscale-authkey.path} \
        ${stateDir}/secrets/tailscale-authkey
    '';
    serviceConfig = {
      PermissionsStartOnly = true;
      # Hard memory cap. Pairs with mem=8192 (qemu allocation)
      # above; cgroup ceiling includes qemu overhead. CI jobs that
      # would overrun (huge nix builds, vscode, etc.) get killed
      # at the VM level rather than at the host level, where they
      # would take everything else down with them.
      MemoryMax = "10G";
      MemorySwapMax = "0";
    };
  };

  # Ping perdurabo-ci every 5 min; restart microvm@forgejo-runner
  # after 3 consecutive misses.
  systemd.services.perdurabo-ci-tailscale-watchdog = {
    description = "Restart microvm@forgejo-runner if perdurabo-ci falls off the tailnet";
    serviceConfig = {
      Type = "oneshot";
      # Counter file persists across timer fires within the same
      # boot; /run is tmpfs so a reboot clears the count and we
      # start fresh.
      StateDirectory = "perdurabo-ci-watchdog";
    };
    path = [ pkgs.tailscale pkgs.systemd pkgs.coreutils ];
    script = ''
      counter=/var/lib/perdurabo-ci-watchdog/miss-count
      [ -f "$counter" ] || echo 0 > "$counter"
      n=$(cat "$counter")
      if tailscale ping -c 1 --timeout 3s perdurabo-ci >/dev/null 2>&1; then
        echo 0 > "$counter"
        exit 0
      fi
      n=$((n + 1))
      echo "$n" > "$counter"
      if [ "$n" -ge 3 ]; then
        echo "perdurabo-ci missed $n consecutive pings; restarting microvm@forgejo-runner" >&2
        systemctl restart microvm@forgejo-runner
        echo 0 > "$counter"
      fi
    '';
  };
  systemd.timers.perdurabo-ci-tailscale-watchdog = {
    description = "Run perdurabo-ci-tailscale-watchdog every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      AccuracySec = "30s";
    };
  };
}
