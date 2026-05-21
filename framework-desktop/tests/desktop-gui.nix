{ pkgs ? import <nixpkgs> {}, pkgs-unstable ? pkgs, lib ? pkgs.lib }:

# GUI test with screenshots - follows official NixOS GNOME test pattern
# This test may be flaky in CI due to graphics requirements

pkgs.testers.nixosTest {
  name = "desktop-gui-test";

  globalTimeout = 600;

  meta = with pkgs.lib.maintainers; {
    maintainers = [ ];
  };

  nodes.machine = { config, pkgs, lib, ... }: {
    imports = [
      # Use the common user-account pattern from nixpkgs tests
      <nixpkgs/nixos/tests/common/user-account.nix>
    ];

    services.xserver.enable = true;

    services.displayManager.gdm = {
      enable = true;
      debug = true;
    };

    services.displayManager.autoLogin = {
      enable = true;
      user = "alice";
    };

    services.desktopManager.gnome.enable = true;
    services.desktopManager.gnome.debug = true;

    # GNOME Shell unsafe mode for test introspection
    systemd.user.services."org.gnome.Shell@wayland" = {
      serviceConfig.ExecStart = [
        ""
        "${pkgs.gnome-shell}/bin/gnome-shell --unsafe-mode"
      ];
    };

    # Add test packages
    environment.systemPackages = with pkgs; [
      gnome-terminal
      firefox
    ];
  };

  testScript = { nodes, ... }:
    let
      user = nodes.machine.users.users.alice;
      uid = toString user.uid;
      bus = "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus";
      run = command: "su - ${user.name} -c '${bus} ${command}'";
      eval = command: run "gdbus call --session -d org.gnome.Shell -o /org/gnome/Shell -m org.gnome.Shell.Eval ${command}";
      startingUp = eval "Main.layoutManager._startingUp";
    in
    ''
      print("\n" + "="*60)
      print("GNOME GUI TEST WITH SCREENSHOTS")
      print("="*60)

      with subtest("Login to GNOME with GDM"):
          machine.wait_for_unit("display-manager.service")
          print("[PASS] GDM service started")

          machine.wait_for_file("/run/user/${uid}/wayland-0")
          print("[PASS] Wayland server running")

          machine.wait_for_unit("default.target", "${user.name}")
          print("[PASS] User session started")

      with subtest("Wait for GNOME Shell"):
          machine.wait_until_succeeds(
              "${startingUp} | grep -q 'true,..false'"
          )
          print("[PASS] GNOME Shell startup completed")

      with subtest("Take screenshots"):
          machine.send_key("esc")
          machine.sleep(5)
          machine.screenshot("gnome_desktop")
          print("[PASS] Desktop screenshot captured")

      with subtest("Launch Firefox"):
          machine.succeed("${run "firefox about:blank &"}")
          machine.sleep(10)
          machine.screenshot("gnome_firefox")
          print("[PASS] Firefox screenshot captured")

      print("\n" + "="*60)
      print("GUI TEST COMPLETED")
      print("="*60)
    '';
}
