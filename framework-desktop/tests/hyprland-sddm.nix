{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

pkgs.nixosTest {
  name = "hyprland-sddm-test";

  meta = with pkgs.lib.maintainers; {
    maintainers = [ ];
  };

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/audio.nix
      ../modules/graphics.nix
      ../modules/hyprland/hyprland.nix
      ../modules/hyprland/rofi.nix
      ../modules/hyprland/waybar.nix
      ../modules/networking.nix
      ../modules/security.nix
      ../modules/shell.nix
      # Excluding system.nix from VM tests to avoid nixpkgs.config conflicts
      ../modules/themes.nix  # SDDM themes
      # Excluding unfree.nix from VM tests to avoid nixpkgs.config conflicts
      ../modules/user-config.nix
      ../modules/virtualization.nix
    ];

    # System essentials (from system.nix but without nixpkgs.config)
    system.stateVersion = "25.05";
    services.displayManager.sddm.theme-config = "astronaut-hacker";

    # Disable heavy services for faster VM tests (only if they exist)
    services.tailscale.enable = lib.mkForce false;

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

      # Minimal autostart - waybar with fallback
      exec-once = sleep 2 && waybar
    '';

    # VM-specific configurations - optimized for speed
    virtualisation = {
      memorySize = 1024;  # Reduced memory
      cores = 1;          # Single core for faster startup
      qemu.options = [
        "-vga std"
        "-netdev user,id=net0"
        "-device virtio-net,netdev=net0"
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

    # Set Hyprland as default session
    services.displayManager.defaultSession = "hyprland-uwsm";

    # Create test user
    users.users.testuser = {
      isNormalUser = true;
      password = "";  # Empty password for VM test only
      extraGroups = [ "wheel" ];
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

    # Wait for Hyprland to start (simplified check)
    machine.wait_until_succeeds("pgrep Hyprland", timeout=20)
    print("✓ Hyprland process started")

    # Check waybar starts with longer timeout
    machine.wait_until_succeeds("pgrep waybar", timeout=30)
    print("Waybar process started")

    # Final screenshot
    machine.screenshot("hyprland_desktop")

    print("✓ SDDM and Hyprland test completed successfully")
  '';
}