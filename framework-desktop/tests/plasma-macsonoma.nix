# NixOS VM test for Plasma 6 with basic KDE setup
{ pkgs, lib, ... }:

pkgs.testers.runNixOSTest {
  name = "plasma-macsonoma";

  nodes.machine = { config, pkgs, lib, ... }: {
    # Enable X11 and KDE Plasma 6
    services.xserver.enable = true;
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
    };
    services.desktopManager.plasma6.enable = true;

    # Essential KDE packages for testing
    environment.systemPackages = with pkgs; [
      kdePackages.plasma-desktop
      kdePackages.kwin
      kdePackages.kglobalaccel
      kdePackages.kscreenlocker
      konsole
      dolphin
      firefox
    ];

    # Auto-login for testing
    services.displayManager.autoLogin = {
      enable = true;
      user = "testuser";
    };

    # Create test user
    users.users.testuser = {
      isNormalUser = true;
      password = "test";
      extraGroups = [ "wheel" ];
    };

    # VM-specific configuration
    virtualisation = {
      memorySize = 4096;
      cores = 2;
      diskSize = 8192;
      graphics = true;
      resolution = { x = 1024; y = 768; };
    };
  };

  testScript = ''
    import time

    # Start the VM
    machine.start()

    # Wait for system to fully boot
    machine.wait_for_unit("multi-user.target")
    print("✓ System booted")

    # Check SDDM service starts
    machine.wait_for_unit("sddm.service", timeout=60)
    print("✓ SDDM service started")

    # Wait for X server to start
    machine.wait_for_x()
    print("✓ X11 server started")

    # Wait for auto-login and desktop to load
    machine.wait_for_unit("plasma-plasmashell.service", timeout=120)
    machine.wait_for_unit("plasma-kwin_x11.service", timeout=60)
    print("✓ Plasma desktop services started")

    # Give desktop time to fully initialize
    time.sleep(15)

    # Check that essential KDE processes are running
    machine.succeed("pgrep plasmashell")
    machine.succeed("pgrep kwin_x11")
    machine.succeed("pgrep kglobalaccel")
    print("✓ Essential KDE processes running")

    # Check for recent crashes or core dumps
    machine.fail("journalctl --since='10 minutes ago' | grep -i 'core dumped'")
    machine.fail("journalctl --since='10 minutes ago' | grep -i 'segmentation fault'")
    print("✓ No crashes detected")

    # Take screenshot of desktop
    machine.screenshot("01_plasma_desktop_loaded")

    # Test basic desktop interaction - open application launcher
    machine.send_key("alt-f1")  # Open application launcher
    time.sleep(3)
    machine.screenshot("02_application_launcher")

    # Test opening an application
    machine.send_key("alt-f2")  # Open KRunner
    time.sleep(2)
    machine.send_chars("konsole")
    machine.send_key("ret")
    time.sleep(5)
    machine.screenshot("03_konsole_opened")

    # Verify konsole window appeared
    machine.succeed("xdotool search --name konsole")
    print("✓ Konsole application launched successfully")

    # Test file manager
    machine.send_key("alt-f2")
    time.sleep(2)
    machine.send_chars("dolphin")
    machine.send_key("ret")
    time.sleep(5)
    machine.screenshot("04_dolphin_opened")

    # Test system settings to verify theme integration
    machine.send_key("alt-f2")
    time.sleep(2)
    machine.send_chars("systemsettings")
    machine.send_key("ret")
    time.sleep(5)
    machine.screenshot("05_systemsettings")

    # Final desktop state
    time.sleep(5)
    machine.screenshot("06_final_desktop_state")

    print("✓ All tests completed successfully!")
  '';
}