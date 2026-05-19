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
    claude = { mac = "02:00:00:00:ae:01"; ip = "10.0.42.11"; sshPort = 2201; };
    codex  = { mac = "02:00:00:00:ae:02"; ip = "10.0.42.12"; sshPort = 2202; };
    gemini = { mac = "02:00:00:00:ae:03"; ip = "10.0.42.13"; sshPort = 2203; };
  };

  # Each guest gets every agent CLI so claude can shell out to codex/gemini
  # and vice versa.
  allAgentPackages = with pkgs; [ claude-code codex gemini-cli ];

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
        packages = allAgentPackages;
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
          {
            source = "${userHomeState}/${name}-sshd";
            mountPoint = "/var/lib/sshd-hostkeys";
            tag = "agent-sshd";
            proto = "virtiofs";
          }
          # Mount the parent dir so each guest can read the others'
          # ~/.claude/projects, ~/.codex/sessions, etc. at ~/peers/<agent>/.
          # Same uid mapping (1000 on host = agent in guest) means perms
          # carry through cleanly.
          {
            source = userHomeState;
            mountPoint = "/home/agent/peers";
            tag = "agent-peers";
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
    "d ${userHomeState}/claude-sshd  0700 root  root  -"
    "d ${userHomeState}/codex-sshd   0700 root  root  -"
    "d ${userHomeState}/gemini-sshd  0700 root  root  -"
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

  # Don't let nixos-rebuild switch bounce running VMs - it would drop any
  # active claude/codex/gemini session. New config sits on disk; pick it
  # up with `claude-restart` etc. or `ai-restart-all` when convenient.
  systemd.services = lib.genAttrs
    (map (n: "microvm@${n}") (lib.attrNames agents))
    (_: { restartIfChanged = false; });

  environment.systemPackages = [ inputs.microvm.packages.x86_64-linux.microvm ];
}
