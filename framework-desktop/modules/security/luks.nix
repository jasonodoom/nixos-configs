# LUKS disk encryption with SSH and Tailscale unlock
{ config, pkgs, lib, ... }:

{
  # CRITICAL: initrd SSH configuration for remote LUKS unlock
  # Test changes with: nixos-rebuild build && verify initrd SSH before switching

  # Enable network and SSH in initrd for remote unlock
  boot.initrd = {
    # Enable systemd in initrd (required for Tailscale)
    systemd.enable = true;

    # Add commands needed for display-ip script
    systemd.extraBin = {
      ip = "${pkgs.iproute2}/bin/ip";
      sed = "${pkgs.gnused}/bin/sed";
      head = "${pkgs.coreutils}/bin/head";
    };

    # SSH host key management for initrd
    # The key at /etc/secrets/initrd/ssh_host_ed25519_key is auto-generated via system.activationScripts
    # and embedded in initrd via boot.initrd.network.ssh.hostKeys

    # Add Tailscale to initrd for remote LUKS unlock
    # Key settings: Reusable, Ephemeral, Pre-authorized
    # Must be plaintext like SSH host key (agenix can't decrypt in initrd)
    secrets."/etc/tailscale/auth-key" = "/etc/secrets/initrd/tailscale-auth-key";

    # Add Tailscale package to initrd (systemd stage 1)
    systemd.storePaths = [ pkgs.tailscale ];

    systemd.services.tailscale-initrd = {
      description = "Tailscale in initrd for remote unlock";
      wantedBy = [ "initrd.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      before = [ "cryptsetup.target" ];

      serviceConfig = {
        Type = "notify";
        ExecStartPre = "/bin/mkdir -p /var/lib/tailscale";
        ExecStart = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock";
        ExecStartPost = "/bin/sh -c 'sleep 2 && ${pkgs.tailscale}/bin/tailscale up --auth-key=$(cat /etc/tailscale/auth-key) --hostname=perdurabo-initrd'";
        Restart = "on-failure";
      };
    };

    # Systemd-based network configuration for initrd
    # Use DHCP for reliability
    systemd.network = {
      enable = true;
      networks."10-ethernet" = {
        matchConfig.Name = "enp191s0";
        networkConfig = {
          DHCP = "yes";
        };
        dhcpV4Config = {
          RouteMetric = 100;
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };

    # Enable network wait service to ensure network is up before SSH
    systemd.services.systemd-networkd-wait-online = {
      enable = true;
      serviceConfig.TimeoutStartSec = "30s";
    };

    # Display IP address on console after network is up
    systemd.services.display-ip = {
      description = "Display IP address for SSH access";
      wantedBy = [ "sysinit.target" ];
      after = [ "network-online.target" "sshd.service" "tailscale-initrd.service" ];
      requiredBy = [ "sshd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
      script = ''
        sleep 5
        IP=$(ip -4 addr show enp191s0 | sed -n 's/.*inet \([0-9.]*\).*/\1/p' | head -1)
        if [ -n "$IP" ]; then
          MSG="
          ========================================
          SSH available at: $IP:6666
          Tailscale: ssh -p 6666 root@perdurabo-initrd
          Local: ssh -p 6666 root@$IP
          ========================================"
          echo "$MSG"
          echo "$MSG" > /dev/tty1 2>/dev/null || true
          echo "$MSG" > /dev/console 2>/dev/null || true
        fi
      '';
    };

    # SSH configuration for initrd unlock
    network.ssh = {
      enable = true;
      port = 6666;
      # Use dedicated initrd SSH host key
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICUc9Otz8oBlWJ1y5oc9x2dBnSJ4Zi3rzJnlAz+eEV7 jason@theophany.local"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ== cardno:5252959"
      ];
    };

    # Unlock script wrapper (called by SSH shell)
    network.postCommands = ''
      echo "LUKS unlocked successfully via Tailscale/SSH. System will continue booting..."
      exit 0
    '';
  };

  # Generate initrd SSH host key at activation time (before initrd is built)
  system.activationScripts.initrdSshHostKey = lib.stringAfter [ "agenix" ] ''
    INITRD_DIR="/etc/secrets/initrd"
    INITRD_KEY="$INITRD_DIR/ssh_host_ed25519_key"

    # Create directory if it doesn't exist
    mkdir -p "$INITRD_DIR"
    chmod 700 "$INITRD_DIR"

    # Generate key if it doesn't exist
    if [ ! -f "$INITRD_KEY" ]; then
      echo "Generating initrd SSH host key..."
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$INITRD_KEY" -N "" -C "perdurabo-initrd"
      chmod 600 "$INITRD_KEY"
      chmod 644 "$INITRD_KEY.pub"
    fi
  '';
}
