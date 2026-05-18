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
in
{
  options.my.aiAgent = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Short name for this agent (claude, codex, gemini).";
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
      python3
      openssh
    ]);

    # Required to run claude-code (Bun standalone) without patching it -
    # the binary's PT_INTERP is /lib64/ld-linux-x86-64.so.2 and patchelf
    # corrupts its embedded JS payload.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
      ];
    };

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
  };
}
