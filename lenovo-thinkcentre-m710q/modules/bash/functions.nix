# Bash Functions Configuration for Congo Server
{ config, pkgs, lib, ... }:

{
  environment.shellInit = ''
    # Container status function
    cstat() {
      echo -e "\033[1;43mServices:\033[0m"
      for container in openbao pihole openvpn; do
        if systemctl is-active container@$container >/dev/null 2>&1; then
          echo -e "  $container: \033[1;32m●\033[0m"
        else
          echo -e "  $container: \033[1;31m○\033[0m"
        fi
      done
    }

    # Network connections
    netmon() {
      echo -e "\033[1;34mConnections:\033[0m"
      netstat -tuln
    }

    # Security status
    secstat() {
      if command -v fail2ban-client >/dev/null 2>&1; then
        banned=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "0")
        echo -e "\033[1;31mSSH banned IPs:\033[0m $banned"
      fi
    }

    # Recent security events
    security_events() {
      echo -e "\033[1;31mRecent Security Events:\033[0m"
      echo -e "\033[1;34mFail2ban bans (last 10):\033[0m"
      journalctl -u fail2ban --since "24 hours ago" | grep -i "ban" | tail -10 | while read line; do
        echo -e "  \033[1;31m●\033[0m $line"
      done
      echo -e "\033[1;34mSSH login attempts (last 5):\033[0m"
      journalctl -u sshd --since "1 hour ago" | grep -E "(Failed|Accepted)" | tail -5 | while read line; do
        if echo "$line" | grep -q "Failed"; then
          echo -e "  \033[1;31m✗\033[0m $line"
        else
          echo -e "  \033[1;32m✓\033[0m $line"
        fi
      done
    }

    # Fail2ban: unban IP address
    unban() {
      if [ -z "$1" ]; then
        echo "Usage: unban <IP_ADDRESS>"
        echo "Example: unban 192.168.1.100"
        return 1
      fi
      echo "Unbanning IP: $1"
      doas fail2ban-client set sshd unbanip "$1"
      echo "Done. Current banned IPs:"
      doas fail2ban-client status sshd | grep "Banned IP"
    }

    # Fail2ban: manually ban IP address
    banip() {
      if [ -z "$1" ]; then
        echo "Usage: banip <IP_ADDRESS>"
        echo "Example: banip 192.168.1.100"
        return 1
      fi
      echo "Banning IP: $1"
      doas fail2ban-client set sshd banip "$1"
      echo "Done. Current banned IPs:"
      doas fail2ban-client status sshd | grep "Banned IP"
    }

    # Fail2ban: unban all IPs
    unbanall() {
      echo "Unbanning all IPs from all jails..."
      doas fail2ban-client unban --all
      echo "Done. Remaining banned IPs:"
      doas fail2ban-client status sshd | grep "Banned IP"
    }

    # VM disk storage directory
    VM_DISK_DIR="$HOME/.vm-disks"

    # Build NixOS Calamares ISO
    build-iso() {
      local de="''${1:-gnome}"
      local nixpkgs_path="''${2:-.}"

      if [[ "$de" != "gnome" && "$de" != "plasma" ]]; then
        echo "Usage: build-iso [gnome|plasma] [nixpkgs-path]"
        return 1
      fi

      local config="nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-''${de}.nix"
      [[ "$de" == "plasma" ]] && config="nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"

      echo "Building $de ISO from $nixpkgs_path..."
      nix-build '<nixpkgs/nixos>' \
        -A config.system.build.isoImage \
        -I nixos-config="$config" \
        -I nixpkgs="$nixpkgs_path"
    }

    # Test ISO in QEMU
    test-iso() {
      local persistent=false
      local iso=""

      while [[ $# -gt 0 ]]; do
        case "$1" in
          -p|--persistent) persistent=true; shift ;;
          *) iso="$1"; shift ;;
        esac
      done

      if [[ -z "$iso" ]]; then
        echo "Usage: test-iso [-p] <iso-path>"
        echo "       test-iso result/iso/*.iso        # ephemeral (default)"
        echo "       test-iso -p result/iso/*.iso     # persistent (install & reboot)"
        return 1
      fi

      mkdir -p "$VM_DISK_DIR"
      local disk="$VM_DISK_DIR/test-disk.qcow2"

      if [[ ! -f "$disk" ]]; then
        echo "Creating 20G disk: $disk"
        qemu-img create -f qcow2 "$disk" 20G
      fi

      echo "Connect from theophany: open vnc://perdurabo:5901"

      if [[ "$persistent" == true ]]; then
        echo "Starting QEMU (persistent mode - changes saved)"
        qemu-system-x86_64 -enable-kvm -m 4G \
          -drive file="$disk",format=qcow2 \
          -cdrom "$iso" \
          -boot d \
          -vnc :1
      else
        echo "Starting QEMU (ephemeral mode - changes discarded on shutdown)"
        qemu-system-x86_64 -enable-kvm -m 4G \
          -drive file="$disk",format=qcow2 \
          -cdrom "$iso" \
          -boot d \
          -vnc :1 \
          -snapshot
      fi
    }
  '';
}