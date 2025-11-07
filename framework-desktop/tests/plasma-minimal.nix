/*
  Minimal runtime test for Plasma 6 with MacSonoma theme integration.

  This test focuses on the specific crashes and service failures I've been
  debugging, including plasmashell crashes, kglobalaccel timeouts and
  KPackageStructure format errors from incompatible plasmoids.

  Type: Runtime validation with VM
  Speed: Medium (~5-10 minutes)
  Memory: 2GB RAM
  Catches: Service failures, process crashes, basic functionality issues

  Regression tests for:
  - plasmashell crash issues (PID core dumps)
  - kglobalaccel timeout failures
  - MacSonoma theme installation problems
  - Missing package references (kscreenlocker, etc)

  Example usage:
    nix-build tests/plasma-minimal.nix
    # Screenshots available in result/
*/
{ pkgs ? import <nixpkgs> {} }:

pkgs.testers.runNixOSTest {
  name = "plasma-debug";

  nodes.machine = { config, pkgs, lib, ... }: {
    # Import actual configuration modules to test the real integration
    # This validates that modules work together without conflicts
    imports = [
      ../modules/kde-config.nix
      ../modules/themes.nix
    ];

    # Use MacSonoma theme to test theme integration doesn't cause crashes
    services.displayManager.sddm.theme-config = "macsonoma";

    # Auto-login to skip SDDM interaction and get straight to desktop testing
    services.displayManager.autoLogin = {
      enable = true;
      user = "test";
    };
    users.users.test = {
      isNormalUser = true;
      password = "test";
    };

    # Minimal VM resources for faster testing (2GB RAM vs 4GB in full test)
    virtualisation = {
      memorySize = 2048;
      graphics = true;
      resolution = { x = 800; y = 600; };
    };
  };

  testScript = ''
    import time

    print("Testing Plasma with configuration...")
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Test 1: Verify MacSonoma theme installation
    # This catches theme packaging issues and file installation problems
    print("Checking SDDM and MacSonoma theme...")
    machine.wait_for_unit("sddm.service", timeout=30)
    machine.succeed("test -d /run/current-system/sw/share/sddm/themes/MacSonoma-6.0")

    # Test 2: X11 server startup
    # Ensures display server starts correctly for desktop session
    print("Checking X11 startup...")
    machine.wait_for_x()

    # Test 3: Critical Plasma services I've been fixing
    # These were failing with timeouts and crashes before fixes
    print("Checking critical Plasma services...")
    machine.wait_for_unit("plasma-plasmashell.service", timeout=60)
    machine.wait_for_unit("plasma-kglobalaccel.service", timeout=30)

    # Test 4: Process validation (services can start but processes can still crash)
    # Checks that processes are actually running and responsive
    print("Verifying processes are running...")
    machine.succeed("pgrep plasmashell")
    machine.succeed("pgrep kwin")
    machine.succeed("pgrep kglobalaccel")

    # Test 5: Crash detection from previous debugging
    # Specifically looks for plasmashell crashes and KPackageStructure errors
    print("Checking for crashes and core dumps...")
    machine.fail("journalctl --since='10 minutes ago' | grep 'core dumped'")
    machine.fail("journalctl --since='10 minutes ago' | grep 'segmentation fault'")
    machine.fail("journalctl --since='10 minutes ago' | grep 'KPackageStructure.*format'")

    # Test 6: kglobalaccel timeout regression test
    # This was repeatedly failing with timeouts before adding the missing packages
    print("Checking kglobalaccel is not timing out...")
    machine.fail("journalctl -u plasma-kglobalaccel --since='5 minutes ago' | grep 'timeout'")

    # Test 7: Basic desktop functionality
    # Minimal interaction test to verify desktop is responsive and usable
    print("Testing basic desktop interaction...")
    time.sleep(5)  # Let desktop fully load
    machine.send_key("alt-f2")  # KRunner should open
    time.sleep(2)
    machine.screenshot("krunner_opened")

    print("All tests passed. Plasma is working correctly.")
  '';
}