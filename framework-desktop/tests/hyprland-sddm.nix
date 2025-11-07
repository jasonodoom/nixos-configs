{ pkgs ? import <nixpkgs> {} }:

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
      ../modules/system.nix
      ../modules/themes.nix  # SDDM themes
      # Excluding unfree.nix from VM tests to avoid nixpkgs.config conflicts
      ../modules/user-config.nix
      ../modules/virtualization.nix
    ];

    # VM-specific configurations
    virtualisation = {
      memorySize = 2048;
      cores = 2;
      qemu.options = [ "-vga std" ];
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

    # Wait for SDDM to start
    machine.wait_for_unit("display-manager.service")
    machine.wait_until_succeeds("systemctl is-active display-manager.service")

    # Wait for SDDM interface to be ready
    machine.wait_for_console_text("Started SDDM")
    machine.sleep(5)  # Give SDDM time to fully load

    # Take screenshot of SDDM login screen
    machine.screenshot("sddm_login_screen")

    # Check that the astronaut-hacker theme loaded (look for theme elements)
    machine.wait_for_text("testuser")  # User should be visible in login screen

    # Attempt login (empty password)
    machine.send_key("ret")

    # Wait for Hyprland to start
    machine.wait_for_console_text("Started Hyprland")
    machine.sleep(10)  # Give Hyprland time to fully start

    # Take screenshot of Hyprland desktop
    machine.screenshot("hyprland_desktop")

    # Check that waybar is running
    machine.succeed("pgrep waybar")

    # Test rofi launch (Super+R equivalent)
    machine.send_key("cmd-r")  # This simulates Super+R
    machine.sleep(2)
    machine.screenshot("rofi_launcher")

    # Close rofi
    machine.send_key("esc")
    machine.sleep(1)

    # Final desktop screenshot
    machine.screenshot("hyprland_final")

    # Check that key processes are running
    machine.succeed("pgrep hyprland")
    machine.succeed("pgrep waybar")

    print("SDDM and Hyprland test completed successfully")
  '';
}