{ pkgs ? import <nixpkgs> {}, pkgs-unstable ? pkgs, lib ? pkgs.lib }:

pkgs.nixosTest {
  name = "hyprland-sddm-test";

  meta = with pkgs.lib.maintainers; {
    maintainers = [ ];
  };

  nodes.machine = { config, pkgs, lib, ... }: {
    _module.args.pkgs-unstable = pkgs-unstable;
    imports = [
      ../modules/audio.nix
      ../modules/fonts.nix    # Required for proper icon rendering
      ../modules/graphics.nix
      # NOT importing hyprland modules - will configure minimal hyprland below
      ../modules/networking.nix
      ../modules/security.nix
      ../modules/shell.nix
      # Excluding system.nix from VM tests to avoid nixpkgs.config conflicts
      # Excluding themes.nix from VM tests to avoid SDDM theme conflicts
      # Excluding unfree.nix from VM tests to avoid nixpkgs.config conflicts
      ../modules/user-config.nix
      ../modules/virtualization.nix
    ];

    # System essentials (from system.nix but without nixpkgs.config)
    system.stateVersion = "25.05";

    # Minimal Hyprland configuration for VM test (no UWSM)
    programs.hyprland = {
      enable = true;
      withUWSM = false;  # Disable UWSM for VM test
      xwayland.enable = true;
    };

    # Use simple built-in theme for VM test to avoid QML issues
    services.displayManager.sddm.theme = lib.mkForce "breeze";

    # Disable heavy services for faster VM tests
    services.tailscale.enable = lib.mkForce false;
    virtualisation.docker.enable = lib.mkForce false;
    virtualisation.libvirtd.enable = lib.mkForce false;

    # Disable hypridle systemd service for VM test (causes startup issues)
    systemd.user.services.hypridle.enable = lib.mkForce false;

    # Simple networking for VM test - override networking module
    networking.networkmanager.enable = lib.mkForce false;
    networking.useDHCP = lib.mkForce true;
    networking.wireless.enable = lib.mkForce false;

    # Minimal Hyprland configuration for fast VM testing
    environment.etc."hypr/hyprland.conf".text = lib.mkForce ''
      # Monitor configuration for VM
      monitor=,preferred,auto,1

      # Minimal configuration for testing only
      general {
        gaps_in = 0
        gaps_out = 0
        border_size = 1
        col.active_border = rgba(7aa2f7ff)
        col.inactive_border = rgba(414868ff)
        layout = dwindle
      }

      decoration {
        rounding = 0
        drop_shadow = false
        blur {
          enabled = false
        }
      }

      animations {
        enabled = false  # Disable animations for faster testing
      }

      input {
        kb_layout = us
        follow_mouse = 1
      }

      # Single workspace for testing
      workspace = 1, defaultName:test, default:true

      # Minimal autostart - no heavy widgets for VM test
      exec-once = sleep 2 && waybar
      # Skip hypridle, dunst, and other services for VM test
    '';

    # VM-specific configurations - optimized for speed
    virtualisation = {
      memorySize = 3072;  # Increased for fonts and Hyprland stability
      cores = 2;          # More cores for better performance
      diskSize = 4096;    # More disk space for fonts
      qemu.options = [
        "-vga virtio"     # Better graphics for Hyprland
        "-netdev user,id=net0"
        "-device virtio-net,netdev=net0"
        "-machine accel=tcg"  # Ensure software acceleration
        "-device virtio-rng-pci"  # Better entropy for faster boot
      ];
      useBootLoader = false;  # Skip bootloader for faster boot
      useEFIBoot = false;
    };

    # Ensure graphics work in VM
    services.xserver = {
      enable = true;
      videoDrivers = [ "qxl" "modesetting" ];
    };

    # Make sure SDDM starts
    services.displayManager.sddm.enable = true;

    # Set Hyprland as default session (use standard hyprland for VM test)
    services.displayManager.defaultSession = "hyprland";

    # Create test user
    users.users.testuser = {
      isNormalUser = true;
      password = "";  # Empty password for VM test only
      extraGroups = [ "wheel" ];
    };

    # Wayland environment for VM test
    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
    };
  };

  testScript = ''
    start_all()

    # Wait for the system to boot
    machine.wait_for_unit("multi-user.target")
    print("✓ System booted")

    # Wait for SDDM to start
    machine.wait_for_unit("display-manager.service")
    machine.wait_until_succeeds("systemctl is-active display-manager.service")
    print("✓ SDDM service active")

    # Quick check - take screenshot and verify SDDM is running
    machine.sleep(5)  # Brief wait for SDDM to start
    machine.screenshot("sddm_login_screen")

    # Simple login test - just press enter to login with empty password
    machine.send_key("ret")
    print("✓ Login attempt made")

    # Wait for Hyprland to start (simplified check) - increased timeout
    machine.wait_until_succeeds("pgrep Hyprland", timeout=60)
    print("✓ Hyprland process started")

    # Check waybar starts with longer timeout
    machine.wait_until_succeeds("pgrep waybar", timeout=30)
    print("Waybar process started")

    # Final screenshot
    machine.screenshot("hyprland_desktop")

    print("✓ SDDM and Hyprland test completed successfully")
  '';
}