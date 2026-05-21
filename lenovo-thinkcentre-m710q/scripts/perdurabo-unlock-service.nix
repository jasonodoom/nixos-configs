# Systemd service for perdurabo to automatically unlock Congo
# Add this to perdurabo's configuration.nix

{ config, pkgs, lib, ... }:

{
  # Congo unlock script
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "congo-unlock" ''
      exec ${./congo-unlock.sh} "$@"
    '')
  ];

  # Systemd service to monitor and unlock Congo
  systemd.services.congo-unlock-monitor = {
    description = "Monitor and unlock Congo server";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      User = "jason";  # Adjust to your user
      Group = "users";
      Restart = "always";
      RestartSec = 30;
      Environment = [
        "HOME=/home/jason"
        "PATH=${lib.makeBinPath [ pkgs.openssh pkgs.coreutils pkgs.bash ]}"
      ];
    };

    script = ''
      # Congo monitoring and auto-unlock
      while true; do
        # Check if Congo needs unlocking
        if timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes \
           -i /home/jason/.ssh/congo_unlock -p 2222 \
           root@192.168.1.100 "echo initrd-check" >/dev/null 2>&1; then

          echo "$(date): Congo detected in initrd - starting unlock process"
          ${./congo-unlock.sh} auto

          # Wait before checking again
          sleep 300
        else
          # Check if Congo is fully booted
          if timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes \
             -i /home/jason/.ssh/id_ed25519 -p 2222 \
             jason@192.168.1.100 "echo boot-check" >/dev/null 2>&1; then

            # Congo is operational, check less frequently
            sleep 60
          else
            # Congo is unreachable, check more frequently
            sleep 30
          fi
        fi
      done
    '';
  };

  # Timer to start unlock process on perdurabo boot
  systemd.services.congo-unlock-on-boot = {
    description = "Unlock Congo on perdurabo startup";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "jason";
      Group = "users";
      Environment = [
        "HOME=/home/jason"
      ];
    };

    script = ''
      # Wait a bit for network to stabilize
      sleep 30

      # Try to unlock Congo
      ${./congo-unlock.sh} auto || true
    '';
  };

  systemd.timers.congo-unlock-on-boot = {
    description = "Start Congo unlock after perdurabo boots";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      Unit = "congo-unlock-on-boot.service";
    };
  };

  # Optional: Add to user's PATH
  programs.bash.shellAliases = {
    "congo-status" = "congo-unlock check";
    "congo-unlock-now" = "congo-unlock auto";
    "congo-monitor" = "congo-unlock monitor";
  };

  # SSH client config for Congo unlock
  programs.ssh.extraConfig = ''
    Host congo-unlock
      HostName 192.168.1.100
      Port 2222
      User root
      IdentityFile ~/.ssh/congo_unlock
      IdentitiesOnly yes
      StrictHostKeyChecking accept-new
      ConnectTimeout 10

    Host congo
      HostName 192.168.1.100
      Port 2222
      User jason
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes
      StrictHostKeyChecking accept-new
  '';
}
