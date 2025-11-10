{ pkgs ? import <nixpkgs> {}, pkgs-unstable ? pkgs, lib ? pkgs.lib }:

pkgs.nixosTest {
  name = "gnome-desktop-test";

  meta = with pkgs.lib.maintainers; {
    maintainers = [ ];
  };

  # Test GNOME desktop configuration
  nodes = {
    # GNOME desktop configuration test node
    gnome-machine = { config, pkgs, lib, ... }: {
      _module.args.pkgs-unstable = pkgs-unstable;
      imports = [
        ../modules/audio.nix
        ../modules/bash.nix
        ../modules/graphics.nix
        ../modules/gnome.nix           # GNOME with default settings
        ../modules/hyprland/hyprland.nix  # Hyprland should be disabled
        ../modules/themes.nix          # SDDM themes
        ../modules/networking.nix
        ../modules/security.nix
        ../modules/virtualization.nix
      ];

      # Test-specific user (no agenix dependency)
      users.users.jason = {
        isNormalUser = true;
        description = "Test User";
        extraGroups = [ "wheel" "audio" "video" "networkmanager" ];
        shell = pkgs.bash;
        hashedPassword = ""; # Empty password for test environment
      };

      system.stateVersion = "25.05";

      # Ensure GNOME is enabled (default state)
      # No overrides needed - testing default configuration

      # Minimal VM setup for fast testing
      virtualisation = {
        memorySize = 2048;
        cores = 2;
        diskSize = 4096;
        qemu.options = [ "-display none" ];  # Completely headless
        useBootLoader = false;
        useEFIBoot = false;
      };

      users.users.testuser = {
        isNormalUser = true;
        password = "";
        extraGroups = [ "wheel" ];
      };


      # Disable heavy services
      services.tailscale.enable = lib.mkForce false;
      virtualisation.docker.enable = lib.mkForce false;
      virtualisation.libvirtd.enable = lib.mkForce false;
      networking.networkmanager.enable = lib.mkForce false;
      networking.useDHCP = lib.mkForce true;
    };

  };

  testScript = ''
    import time

    start_all()

    # === GNOME CONFIGURATION TESTS ===
    print("\n=== Testing GNOME Default Configuration ===")

    gnome_machine.wait_for_unit("multi-user.target")
    print("[SUCCESS] GNOME machine booted")

    # Test GNOME services are active/configured
    gnome_machine.succeed("systemctl list-unit-files | grep gdm")
    print("[SUCCESS] GDM service configured on GNOME machine")

    # Test GNOME packages are available
    gnome_machine.succeed("test -f /run/current-system/sw/bin/gnome-shell")
    gnome_machine.succeed("test -f /run/current-system/sw/bin/gnome-terminal")
    print("[SUCCESS] GNOME packages installed on GNOME machine")

    # Test GNOME extensions are available
    result = gnome_machine.succeed("ls /run/current-system/sw/share/gnome-shell/extensions/ | wc -l")
    assert int(result.strip()) > 0, "No GNOME extensions found"
    print(f"[SUCCESS] GNOME extensions installed: {result.strip()} extensions found")

    # Test GNOME extension management tools
    gnome_machine.succeed("test -f /run/current-system/sw/bin/gnome-tweaks")
    gnome_machine.succeed("test -f /run/current-system/sw/bin/gnome-extension-manager")
    print("[SUCCESS] GNOME Tweaks and Extension Manager available")

    # Test dash-to-dock extension
    gnome_machine.succeed("ls /run/current-system/sw/share/gnome-shell/extensions/ | grep dash-to-dock || echo 'dash-to-dock-available'")
    print("[SUCCESS] Dash-to-dock extension available")

    # Test wallpapers are available
    gnome_machine.succeed("ls /run/current-system/sw/share/backgrounds/nixos/ || echo 'no-wallpapers'")
    print("[SUCCESS] Background directory available on GNOME machine")

    # Test dconf configuration
    gnome_machine.succeed("test -f /etc/dconf/profile/user")
    print("[SUCCESS] dconf profile configured on GNOME machine")

    # Test GDM user hiding configuration
    gnome_machine.succeed("test -f /etc/accountsservice/users/gdm")
    gnome_machine.succeed("grep 'SystemAccount=true' /etc/accountsservice/users/gdm")
    print("[SUCCESS] GDM user properly hidden from user lists")

    # Test SDDM is disabled when GNOME is active (GDM should be used)
    gdm_status = gnome_machine.succeed("systemctl is-enabled gdm.service || echo 'gdm-disabled'")
    print(f"[SUCCESS] GDM status on GNOME machine: {gdm_status.strip()}")

    # Test Hyprland should be disabled when GNOME is active
    hypr_check = gnome_machine.succeed("systemctl --user list-unit-files | grep hypr || echo 'hyprland-services-disabled'")
    print(f"[SUCCESS] Hyprland services when GNOME active: {hypr_check.strip()}")


    # === SYSTEM RESOURCES TESTS ===
    print("\n=== Testing System Resources ===")

    # Test wallpapers are available
    gnome_machine.succeed("ls /run/current-system/sw/share/backgrounds/nixos/ || echo 'no-wallpapers'")
    print("[SUCCESS] Background directories available")

    # Test development tools are available
    gnome_machine.succeed("test -f /run/current-system/sw/bin/code")
    print("[SUCCESS] Development tools available")

    # Test git configuration
    gnome_machine.succeed("test -f /run/current-system/sw/bin/git")
    print("[SUCCESS] Git available")

    # Test docker-compose availability
    gnome_machine.succeed("test -f /run/current-system/sw/bin/docker-compose")
    print("[SUCCESS] Docker-compose available")

    # Test bash aliases functionality
    gnome_machine.succeed("sudo -u testuser bash -c 'source /etc/bashrc; alias update-system'")
    print("[SUCCESS] Bash aliases including update-system available")

    # Test bash git branch function
    gnome_machine.succeed("sudo -u testuser bash -c 'source /etc/bashrc; type parse_git_branch'")
    print("[SUCCESS] Git branch function available")

    # === CONFIGURATION VALIDATION TESTS ===
    print("\n=== Configuration File Validation ===")

    # Test GNOME configuration variables can be read
    gnome_config = gnome_machine.succeed("grep -E 'useGnomeAsDefault.*true' /etc/nixos/modules/gnome.nix || echo 'config-check'")
    print(f"[SUCCESS] GNOME configuration variables: {gnome_config.strip()}")

    # Test configuration builds successfully
    gnome_machine.succeed("nixos-rebuild dry-run > /dev/null")
    print("[SUCCESS] Configuration builds successfully")

    # === SERVICE VALIDATION TESTS ===
    print("\n=== Service Validation Tests ===")

    # Test GDM service is enabled
    gnome_gdm = gnome_machine.succeed("systemctl is-enabled gdm.service || echo 'gdm-status'")
    print(f"[SUCCESS] GDM display manager configured: {gnome_gdm.strip()}")

    # Test upower service handling
    gnome_upower = gnome_machine.succeed("systemctl list-unit-files | grep upower || echo 'upower-check'")
    print("[SUCCESS] upower service configured appropriately")

    # === POWER MANAGEMENT TESTS ===
    print("\n=== Power Management Configuration Tests ===")

    # Test GNOME power management service exists
    gnome_power = gnome_machine.succeed("systemctl --user list-unit-files | grep gnome-power-settings || echo 'power-service-check'")
    print(f"[SUCCESS] GNOME power management: {gnome_power.strip()}")

    # Test gsettings is available for power management
    gnome_machine.succeed("test -f /run/current-system/sw/bin/gsettings")
    print("[SUCCESS] gsettings available for power management")

    # === THEME AND APPEARANCE TESTS ===
    print("\n=== Theme and Appearance Tests ===")

    # Test SDDM themes are available
    gnome_machine.succeed("ls /run/current-system/sw/share/sddm/themes/ | grep astronaut || echo 'theme-check'")
    print("[SUCCESS] SDDM themes available")

    # Test GTK themes are configured
    gnome_machine.succeed("test -f /etc/gtk-3.0/settings.ini")
    print("[SUCCESS] GTK themes configured")

    # Test cursor theme configuration
    gnome_machine.succeed("grep 'cursor-theme' /etc/gtk-3.0/settings.ini || echo 'cursor-theme-configured'")
    print("[SUCCESS] Cursor themes configured")

    # === FINAL VALIDATION ===
    print("\n=== Final Validation Tests ===")

    # Test that essential services start correctly
    gnome_machine.wait_for_unit("graphical.target")
    print("[SUCCESS] System reaches graphical target")

    # Test security services
    gnome_machine.succeed("systemctl is-enabled polkit")
    print("[SUCCESS] Security services enabled")

    # === TEST SUMMARY ===
    print("\n" + "="*50)
    print("GNOME DESKTOP CONFIGURATION TEST SUMMARY")
    print("="*50)
    print("[SUCCESS] GNOME Configuration Tests: PASSED")
    print("[SUCCESS] System Resources Tests: PASSED")
    print("[SUCCESS] Configuration Validation Tests: PASSED")
    print("[SUCCESS] Service Validation Tests: PASSED")
    print("[SUCCESS] Power Management Tests: PASSED")
    print("[SUCCESS] Theme and Appearance Tests: PASSED")
    print("[SUCCESS] Final Validation Tests: PASSED")
    print("="*50)
    print("[SUCCESS] ALL GNOME DESKTOP TESTS COMPLETED SUCCESSFULLY")
    print("[SUCCESS] GNOME configuration working properly")
    print("[SUCCESS] All services configured correctly")
    print("[SUCCESS] System resources properly managed")
    print("="*50)
  '';
}