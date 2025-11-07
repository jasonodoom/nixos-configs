# Simple KDE Plasma 6 VM test
{ pkgs ? import <nixpkgs> {} }:

pkgs.testers.runNixOSTest {
  name = "basic-kde";

  nodes.machine = {
    # Enable basic KDE Plasma 6
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    # Create test user
    users.users.testuser = {
      isNormalUser = true;
      password = "test";
    };

    # Auto-login for testing
    services.displayManager.autoLogin = {
      enable = true;
      user = "testuser";
    };

    # VM settings
    virtualisation.memorySize = 2048;
    virtualisation.graphics = true;
  };

  testScript = ''
    # Start machine and wait for boot
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Check SDDM starts
    machine.wait_for_unit("sddm.service")

    # Check X11 starts
    machine.wait_for_x()

    # Check basic KDE services
    machine.wait_for_unit("plasma-plasmashell.service")
    machine.wait_for_unit("plasma-kwin_x11.service")

    # Take a screenshot
    machine.screenshot("kde_desktop")

    print("Basic KDE test completed successfully!")
  '';
}