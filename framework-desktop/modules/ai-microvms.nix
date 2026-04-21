{ config, pkgs, lib, inputs, ... }:

# AI agent microvms on perdurabo.
#
# Each agent runs in its own cloud-hypervisor microvm for host-kernel
# isolation. The host reaches the guest sshd via a Linux bridge
# (virbr-ai, 10.0.42.0/24); bash aliases on the host ssh into the VM
# and invoke the tool binary.
#
# State (OAuth tokens, config) lives in
# /home/jason/.local/state/ai-agents/<name> and is virtiofs-shared into
# the guest as /home/agent. ~/code is shared read-write.

let
  userHomeState = "/home/jason/.local/state/ai-agents";
  codeDir = "/home/jason/code";

  hostAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwLk94aSzaUrpxHZ6BHbxMaF3054VZJh6rUF8cdSHIm jason@perdurabo"
  ];

  agents = {
    claude = { mac = "02:00:00:00:ae:01"; ip = "10.0.42.11"; sshPort = 2201; package = pkgs.claude-code; };
    codex  = { mac = "02:00:00:00:ae:02"; ip = "10.0.42.12"; sshPort = 2202; package = pkgs.codex; };
    gemini = { mac = "02:00:00:00:ae:03"; ip = "10.0.42.13"; sshPort = 2203; package = pkgs.gemini-cli; };
  };

  mkAgentVm = name: agent: {
    specialArgs = { inherit inputs; };

    config = { config, pkgs, lib, inputs, ... }: {
      imports = [
        inputs.microvm.nixosModules.microvm
        ../../modules/shared/ai-agent-guest.nix
      ];

      nixpkgs.overlays = [ (import ../overlays/default.nix { inherit inputs; }) ];

      system.stateVersion = "25.11";
      networking.hostName = "ai-${name}";

      my.aiAgent = {
        inherit name;
        packages = [ agent.package ];
        sshPort = agent.sshPort;
        hostPublicKeys = hostAuthorizedKeys;
      };

      microvm = {
        hypervisor = "qemu";
        vcpu = 2;
        mem = 4096;
        balloon = true;

        interfaces = [{
          type = "bridge";
          id = "vm-${name}";
          mac = agent.mac;
          bridge = "virbr-ai";
        }];

        shares = [
          {
            source = "${userHomeState}/${name}";
            mountPoint = "/home/agent";
            tag = "agent-home";
            proto = "virtiofs";
          }
          {
            source = codeDir;
            mountPoint = "/home/agent/code";
            tag = "agent-code";
            proto = "virtiofs";
          }
        ];
      };

      networking.useNetworkd = true;
      networking.useDHCP = false;
      systemd.network.networks."10-eth" = {
        matchConfig.MACAddress = agent.mac;
        address = [ "${agent.ip}/24" ];
        routes = [ { Gateway = "10.0.42.1"; } ];
        dns = [ "1.1.1.1" "8.8.8.8" ];
      };
    };
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${userHomeState}              0750 jason users -"
    "d ${userHomeState}/claude       0750 1000  1000  -"
    "d ${userHomeState}/codex        0750 1000  1000  -"
    "d ${userHomeState}/gemini       0750 1000  1000  -"
  ];

  networking.bridges.virbr-ai.interfaces = [];
  networking.interfaces.virbr-ai.ipv4.addresses = [
    { address = "10.0.42.1"; prefixLength = 24; }
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "virbr-ai" ];
  };

  networking.firewall.trustedInterfaces = [ "virbr-ai" ];

  # qemu-bridge-helper refuses by default; whitelist the AI bridge.
  environment.etc."qemu/bridge.conf".text = ''
    allow virbr-ai
  '';

  microvm.vms = lib.mapAttrs mkAgentVm agents;

  environment.systemPackages = [ inputs.microvm.packages.x86_64-linux.microvm ];
}
