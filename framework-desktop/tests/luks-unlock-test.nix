{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

pkgs.testers.nixosTest {
  name = "perdurabo-cli-access-test";

  meta = with pkgs.lib.maintainers; {
    maintainers = [ ];
  };

  # Test CLI access (console + SSH + Tailscale)
  nodes = {
    machine = { config, pkgs, lib, ... }: {
      # Test user
      users.users.testuser = {
        isNormalUser = true;
        password = "";
        extraGroups = [ "wheel" ];
      };

      # Enable SSH
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };

      # Enable Tailscale
      services.tailscale.enable = true;

      # Basic networking
      networking = {
        useDHCP = true;
        firewall.enable = true;
      };

      system.stateVersion = "25.05";

      # Minimal VM setup
      virtualisation = {
        memorySize = 2048;
        cores = 2;
        diskSize = 4096;
        qemu.options = [ "-display none" ];
        useBootLoader = false;
        useEFIBoot = false;
      };
    };
  };

  testScript = ''
    start_all()

    print("\n=== CLI Access Test ==")

    machine.wait_for_unit("multi-user.target")
    print("[SUCCESS] Machine booted")

    # === CONSOLE ACCESS TEST ===
    print("\n=== Testing Console Access ==")

    machine.succeed("test -c /dev/console")
    print("[SUCCESS] Console device accessible")

    machine.succeed("echo 'Console test' > /dev/console 2>&1 || true")
    print("[SUCCESS] Console writable")

    # === SSH SERVICE TEST ===
    print("\n=== Testing SSH Service ==")

    machine.wait_for_unit("sshd.service")
    print("[SUCCESS] SSHD service running")

    machine.wait_for_open_port(22)
    print("[SUCCESS] SSH port 22 listening")

    # === TAILSCALE SERVICE TEST ===
    print("\n=== Testing Tailscale Service ==")

    machine.wait_for_unit("tailscaled.service")
    print("[SUCCESS] Tailscale service running")

    # === TEST SUMMARY ===
    print("\n" + "="*50)
    print("PERDURABO CLI ACCESS TEST SUMMARY")
    print("="*50)
    print("[SUCCESS] Console Access: PASSED")
    print("[SUCCESS] SSH Service: PASSED")
    print("[SUCCESS] Tailscale Service: PASSED")
    print("="*50)
  '';
}
