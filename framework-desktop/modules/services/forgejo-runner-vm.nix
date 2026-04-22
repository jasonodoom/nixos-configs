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
            network = "host";
            privileged = false;
          };
          runner.capacity = 1;
        };
      };

      networking.firewall.enable = true;
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    };
  };

  systemd.services."microvm@forgejo-runner" = {
    preStart = ''
      install -m 0400 -o microvm -g kvm \
        ${config.age.secrets.forgejo-runner-token.path} \
        ${stateDir}/secrets/runner-token
      install -m 0400 -o microvm -g kvm \
        ${config.age.secrets.forgejo-runner-tailscale-authkey.path} \
        ${stateDir}/secrets/tailscale-authkey
    '';
    serviceConfig.PermissionsStartOnly = true;
  };
}
