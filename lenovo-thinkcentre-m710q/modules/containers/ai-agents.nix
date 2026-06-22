{ config, pkgs, lib, ... }:

# AI agent nspawn containers on congo.
#
# Each agent lives in its own systemd-nspawn container with a veth pair
# giving host-to-guest reachability at a stable address. sshd inside the
# container; bash aliases on the host ssh in and invoke the tool binary.
#
# Persistent state (OAuth tokens, config) lives under
# /home/jason/.local/state/ai-agents/<name> bind-mounted as /home/agent.
# ~/code is bind-mounted read-write so agents can edit real code.

let
  userHomeState = "/home/jason/.local/state/ai-agents";
  codeDir = "/home/jason/code";

  hostAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICUc9Otz8oBlWJ1y5oc9x2dBnSJ4Zi3rzJnlAz+eEV7 jason@theophany.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwLk94aSzaUrpxHZ6BHbxMaF3054VZJh6rUF8cdSHIm jason@perdurabo"
  ];

  agents = {
    claude      = { hostAddress = "10.0.43.1";  localAddress = "10.0.43.2";  sshPort = 2201; };
    codex       = { hostAddress = "10.0.43.5";  localAddress = "10.0.43.6";  sshPort = 2202; };
    antigravity = { hostAddress = "10.0.43.9";  localAddress = "10.0.43.10"; sshPort = 2203; };
  };

  # Each guest gets every agent CLI so claude can shell out to
  # codex/antigravity and vice versa.
  allAgentPackages = with pkgs; [ claude-code codex antigravity-cli ];

  mkContainer = name: agent: {
    autoStart = false;
    privateNetwork = true;
    hostAddress = agent.hostAddress;
    localAddress = agent.localAddress;

    bindMounts = {
      "/home/agent" = {
        hostPath = "${userHomeState}/${name}";
        isReadOnly = false;
      };
      "/home/agent/code" = {
        hostPath = codeDir;
        isReadOnly = false;
      };
      # Mount the parent dir so each guest can read the others'
      # ~/.claude/projects, ~/.codex/sessions, etc. at ~/peers/<agent>/.
      "/home/agent/peers" = {
        hostPath = userHomeState;
        isReadOnly = false;
      };
    };

    config = { config, pkgs, lib, ... }: {
      imports = [ ../../../modules/shared/ai-agent-guest.nix ];

      system.stateVersion = "25.11";
      networking.hostName = "ai-${name}";

      my.aiAgent = {
        inherit name;
        packages = allAgentPackages;
        sshPort = agent.sshPort;
        hostPublicKeys = hostAuthorizedKeys;
      };

      networking.useHostResolvConf = lib.mkForce false;
      networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
      networking.defaultGateway = agent.hostAddress;
    };
  };

  mkResourceLimits = name: {
    name = "systemd-nspawn@${name}";
    value = {
      serviceConfig = {
        MemoryMax = "2G";
        CPUQuota = "200%";
      };
    };
  };
in
{
  systemd.tmpfiles.rules = [
    "d ${userHomeState}              0750 jason users -"
    "d ${userHomeState}/claude       0750 1000  1000  -"
    "d ${userHomeState}/codex        0750 1000  1000  -"
    "d ${userHomeState}/antigravity  0750 1000  1000  -"
  ];

  containers = lib.mapAttrs mkContainer agents;

  systemd.services = lib.listToAttrs
    (map mkResourceLimits (lib.attrNames agents));

  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
  };
}
