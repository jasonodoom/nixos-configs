# LUKS disk encryption with SSH unlock
{ config, pkgs, lib, ... }:

{
  # CRITICAL: initrd SSH configuration for remote LUKS unlock
  # Test changes with: nixos-rebuild build && verify initrd SSH before switching

  # Enable network and SSH in initrd for remote unlock
  boot.initrd = {
    # Enable systemd in initrd (required for Tailscale)
    systemd.enable = true;

    # Add commands needed for display-ip script and auto-reboot
    systemd.extraBin = {
      ip = "${pkgs.iproute2}/bin/ip";
      sed = "${pkgs.gnused}/bin/sed";
      head = "${pkgs.coreutils}/bin/head";
      sleep = "${pkgs.coreutils}/bin/sleep";
    };

    # SSH host key management for initrd
    # https://nixos.wiki/wiki/Remote_disk_unlocking
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/initrd-ssh.nix
    # The key at /etc/secrets/initrd/ssh_host_ed25519_key is auto-generated via system.activationScripts
    # and embedded in initrd via boot.initrd.network.ssh.hostKeys (not boot.initrd.secrets to avoid conflicts)

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
      before = [ "cryptsetup.target" "systemd-cryptsetup@crypted.service" ];

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
    # This runs last so the IP info stays visible
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
          # Try multiple methods to ensure visibility
          echo "$MSG"
          echo "$MSG" > /dev/tty1 2>/dev/null || true
          echo "$MSG" > /dev/console 2>/dev/null || true
        fi
      '';
    };

    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 6666;
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICUc9Otz8oBlWJ1y5oc9x2dBnSJ4Zi3rzJnlAz+eEV7 jason@theophany.local"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ== cardno:5252959"
        ];
      };
    };

    # Automatic LUKS unlock wrapper script for SSH
    systemd.services.create-unlock-script = {
      requiredBy = [ "sshd.service" ];
      before = [ "sshd.service" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /bin
        cat > /bin/unlock-wrapper << 'EOF'
#!/bin/sh
# If SSH session, run unlock command
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
  echo "Unlocking LUKS encrypted disk..."
  /bin/systemd-cryptsetup attach crypted /dev/disk/by-uuid/842e66b5-0b98-4b86-9427-ed94fa425a06
  echo "Disk unlocked. SSH session will disconnect - boot will continue."
  echo "You can reconnect after boot completes."
  # Just exit - systemd will continue boot automatically after disk is unlocked
  exit 0
else
  # Console login - run password agent for console prompt
  exec /bin/systemd-tty-ask-password-agent --query
fi
EOF
        chmod +x /bin/unlock-wrapper
      '';
    };

    # SSH/Console shell for remote unlock in systemd initrd
    # https://github.com/NixOS/nixpkgs/issues/294032
    # https://discourse.nixos.org/t/unlocking-luks-in-initrd-with-systemd-enabled-through-ssh/31052
    systemd.users.root.shell = "/bin/unlock-wrapper";

    # Ensure password prompt appears on console
    # Enable both console and wall password agents
    systemd.services.systemd-ask-password-console.wantedBy = [ "sysinit.target" ];
    systemd.paths.systemd-ask-password-console.wantedBy = [ "sysinit.target" ];
    systemd.services.systemd-ask-password-wall.wantedBy = [ "multi-user.target" ];

    # Auto-reboot after 10 minutes if LUKS is not unlocked
    systemd.services.initrd-timeout-reboot = {
      description = "Reboot if LUKS unlock times out";
      wantedBy = [ "initrd.target" ];
      before = [ "cryptsetup.target" ];
      conflicts = [ "cryptsetup.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/sleep 600 && ${pkgs.systemd}/bin/systemctl reboot";
      };
    };

    # Kernel modules for initrd
    # Network: Tailscale and ethernet drivers
    # Console/Keyboard: for local password entry
    availableKernelModules = [
      # Network
      "r8169" "e1000e" "igb" "tun"
      # Keyboard/Console for local LUKS unlock
      "atkbd" "i8042" "usbhid" "hid_generic"
    ];

    # Force LUKS support in initrd
    luks.forceLuksSupportInInitrd = true;

  };

  # LUKS configuration
  boot.initrd.luks.devices = {
    "crypted" = {
      # Use the UUID of the encrypted partition (nvme0n1p2)
      device = "/dev/disk/by-uuid/842e66b5-0b98-4b86-9427-ed94fa425a06";
      preLVM = true;

      # SSD optimization
      allowDiscards = true;

      # Increase timeout for remote unlock (5 minutes)
      # Gives more time to connect via SSH/Tailscale
      keyFileTimeout = 300;
    };
  };


  # Prevent device timeout on root filesystem
  fileSystems."/".options = [ "x-systemd.device-timeout=0" ];

  # Generate initrd SSH host key automatically if it doesn't exist
  # This runs during system activation BEFORE initrd is built
  # https://nixos.wiki/wiki/Remote_disk_unlocking#Generating_host_keys
  system.activationScripts.initrd-ssh-key = lib.stringAfter [ "specialfs" ] ''
    if [ ! -f /etc/secrets/initrd/ssh_host_ed25519_key ]; then
      echo "Generating initrd SSH host key..."
      mkdir -p /etc/secrets/initrd
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /etc/secrets/initrd/ssh_host_ed25519_key -N "" -C "initrd-ssh-key"
      chmod 600 /etc/secrets/initrd/ssh_host_ed25519_key
      echo "Initrd SSH host key generated at /etc/secrets/initrd/ssh_host_ed25519_key"
    else
      echo "Initrd SSH host key already exists, reusing it"
    fi
  '';

  # Validate initrd SSH configuration after boot
  systemd.services.test-initrd-ssh = {
    description = "Validate initrd SSH configuration after boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Verify initrd SSH key exists
      if [ ! -f /etc/secrets/initrd/ssh_host_ed25519_key ]; then
        echo "WARNING: initrd SSH host key missing! Remote LUKS unlock will fail!"
        exit 1
      fi

      # Verify permissions
      if [ "$(stat -c %a /etc/secrets/initrd/ssh_host_ed25519_key)" != "600" ]; then
        echo "WARNING: initrd SSH host key has incorrect permissions!"
        chmod 600 /etc/secrets/initrd/ssh_host_ed25519_key
      fi

      echo "initrd SSH configuration validated successfully"
    '';
  };

  # Additional packages for LUKS management
  environment.systemPackages = with pkgs; [
    cryptsetup
  ];
}
