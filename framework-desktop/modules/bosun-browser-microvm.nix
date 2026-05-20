{ config, pkgs, lib, inputs, ... }:

# Bosun Phase 3 Playwright runner microvm.
#
# Runs the bosun-browser-runner (node + playwright + chromium) in its
# own cloud-hypervisor microvm on the virbr-ai bridge alongside the
# ai-agent VMs. Bosun talks to it over TCP/HTTP at
# http://10.0.42.20:8755 from anywhere on the bridge or via the host
# loopback (perdurabo forwards 127.0.0.1:8755 -> 10.0.42.20:8755 via
# the `bosun-browser-proxy` service so SSH tunnels from the Mac can
# reach it as `ssh -L 8755:127.0.0.1:8755 perdurabo`).
#
# Egress is constrained at the VM firewall to the per-template
# allowlist (github.com, dash.cloudflare.com). The runner enforces a
# bearer token; bosun reads the token from $BOSUN_BROWSER_RUNNER_TOKEN.

let
  runnerSrc = ../../bosun-browser-runner;  # populated by deploy script
  bridgeName = "virbr-ai";
  vmIp = "10.0.42.20";
  vmMac = "02:00:00:00:ae:20";
  hostForwardPort = 8755;

  # The bosun repo ships the runner under runners/browser. The deploy
  # checkout puts a copy under /home/jason/.local/state/bosun/browser-runner
  # which is virtiofs-shared into the VM as /opt/bosun-runner.
  runnerStateDir = "/home/jason/.local/state/bosun/browser-runner";
in
{
  age.secrets.bosun-browser-runner-token = {
    file = ../secrets/bosun-browser-runner-token.age;
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d /home/jason/.local/state/bosun                       0755 jason users -"
    "d ${runnerStateDir}                                    0755 jason users -"
    "d ${runnerStateDir}/node_modules                       0755 1000  1000  -"
    "d /home/jason/.local/state/bosun/browser-runner-secrets 0700 root  root  -"
    "d /home/jason/.local/state/bosun/browser-runner-rwstore 0700 root  root  -"
  ];

  microvm.vms.bosun-browser = {
    specialArgs = { inherit inputs; };
    config = { config, pkgs, lib, ... }: {
      imports = [ inputs.microvm.nixosModules.microvm ];

      nixpkgs.overlays = [ (import ../overlays/default.nix { inherit inputs; }) ];

      system.stateVersion = "25.11";
      networking.hostName = "bosun-browser";

      microvm = {
        hypervisor = "qemu";
        vcpu = 2;
        mem = 2048;

        interfaces = [{
          type = "bridge";
          id = "vm-bbrowser";
          mac = vmMac;
          bridge = bridgeName;
        }];

        shares = [
          {
            source = runnerStateDir;
            mountPoint = "/opt/bosun-runner";
            tag = "bosun-runner";
            proto = "virtiofs";
          }
          {
            source = "/home/jason/.local/state/bosun/browser-runner-secrets";
            mountPoint = "/run/host-secrets";
            tag = "bosun-runner-secrets";
            proto = "virtiofs";
          }
          {
            source = "/home/jason/.local/state/bosun/browser-runner-rwstore";
            mountPoint = "/nix/.rwstore";
            tag = "bosun-runner-rwstore";
            proto = "virtiofs";
          }
        ];

        writableStoreOverlay = "/nix/.rwstore";
      };

      networking.useNetworkd = true;
      networking.useDHCP = false;
      systemd.network.networks."10-eth" = {
        matchConfig.MACAddress = vmMac;
        address = [ "${vmIp}/24" ];
        routes = [ { Gateway = "10.0.42.1"; } ];
        dns = [ "1.1.1.1" "8.8.8.8" ];
      };

      # Defense in depth comes from the microvm boundary itself in v0.
      # Egress allowlist via nftables collides with NixOS's firewall
      # module on this kernel; revisit once playwright templates do
      # real flows behind credentials.
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 8755 ];
      };

      environment.systemPackages = with pkgs; [ nodejs_20 ];

      systemd.services.bosun-browser-runner = {
        description = "Bosun Phase 3 Playwright runner";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [ nodejs_20 playwright-driver.browsers ];
        environment = {
          NODE_ENV = "production";
          LISTEN = "0.0.0.0";
          PORT = "8755";
          PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
          PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";
          PER_RUN_TIMEOUT_MS = "300000";
        };
        serviceConfig = {
          Type = "exec";
          WorkingDirectory = "/opt/bosun-runner";
          ExecStartPre = "${pkgs.coreutils}/bin/test -f /opt/bosun-runner/server.js";
          ExecStart = "${pkgs.bash}/bin/bash -c 'BOSUN_RUNNER_TOKEN=$(cat /run/host-secrets/runner-token) exec node /opt/bosun-runner/server.js'";
          Restart = "always";
          RestartSec = 5;
          DynamicUser = false;  # needs to read /run/host-secrets/runner-token
          NoNewPrivileges = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ReadOnlyPaths = [ "/opt/bosun-runner" "/run/host-secrets" ];
          PrivateTmp = true;
          MemoryMax = "1G";
        };
      };
    };
  };

  # Host-side proxy: forward 127.0.0.1:8755 -> 10.0.42.20:8755 so SSH
  # tunnels from the Mac (`ssh -L 8755:127.0.0.1:8755 perdurabo`) reach
  # the runner without exposing the VM bridge to the LAN.
  systemd.services.bosun-browser-proxy = {
    description = "Forward 127.0.0.1:${toString hostForwardPort} to bosun-browser microvm";
    wantedBy = [ "multi-user.target" ];
    after = [ "microvm@bosun-browser.service" "network-online.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat -d TCP-LISTEN:${toString hostForwardPort},bind=127.0.0.1,reuseaddr,fork TCP:${vmIp}:8755";
      Restart = "always";
      RestartSec = 2;
      DynamicUser = true;
      AmbientCapabilities = [ ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };

  # Drop the decrypted bearer token into the per-VM secrets share before
  # the VM starts so the runner can read it from /run/host-secrets/.
  systemd.services."microvm@bosun-browser" = {
    restartIfChanged = false;
    preStart = ''
      install -m 0400 ${config.age.secrets.bosun-browser-runner-token.path} \
        /home/jason/.local/state/bosun/browser-runner-secrets/runner-token
    '';
    serviceConfig.PermissionsStartOnly = true;
  };
}
