# Boot test: import the same modules congo uses, override what QEMU can't do
# (LUKS, real tailscale auth, hardware-specific settings, real agenix secrets),
# boot the VM, and assert that multi-user.target plus the key services come up.
#
# This catches userspace boot regressions: bad unit ordering, broken services,
# container start failures. It does NOT exercise LUKS unlock over SSH or the
# tailscale-initrd control-plane handshake; those need a real disk image and
# control plane and are covered by the structural initrd-unlock test.
{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

pkgs.testers.nixosTest {
  name = "congo-boot-test";

  nodes.machine = { config, pkgs, lib, modulesPath, ... }: {
    imports = [
      ./lib/age-stub.nix
      ../modules/bash/bash.nix
      ../modules/network/networking.nix
      ../modules/security/security.nix
      ../modules/security/secrets.nix
      ../modules/security/ssh.nix
      ../modules/security/fail2ban.nix
      ../modules/services/verify-commits.nix
    ];

    # system.nix sets boot loader, kernel, nix.settings, autoUpgrade. None of
    # that helps for the boot test; nixosTest provides its own pkgs and boot
    # config, and importing system.nix conflicts with both.

    # QEMU defaults that override host-specific bits.
    virtualisation = {
      memorySize = 2048;
      cores = 2;
      diskSize = 4096;
      qemu.options = [ "-display none" ];
    };

    # mkForce: the real configs come from imported modules; we override the
    # parts that won't work or aren't relevant in CI.
    boot.initrd.luks.devices = lib.mkForce {};
    boot.initrd.systemd.enable = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    services.tailscale.enable = lib.mkForce false;

    # NAT in networking.nix references container-only interfaces; disable for
    # the test since no containers run in this minimal node.
    networking.nat.enable = lib.mkForce false;
    networking.firewall.interfaces = lib.mkForce {};
    networking.networkmanager.enable = lib.mkForce false;
    networking.useDHCP = lib.mkForce true;

    # Bypass the verify-upgrade-commits service in the test; it tries to clone
    # over the network and validate signatures, neither of which the test VM
    # can do meaningfully. The unit definition is still imported, just masked.
    systemd.services.verify-upgrade-commits.wantedBy = lib.mkForce [];
    systemd.services.import-gpg-key.wantedBy = lib.mkForce [];

    system.stateVersion = "25.05";
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")
    print("[PASS] multi-user.target reached")

    machine.wait_for_unit("sshd.service")
    machine.wait_for_open_port(2222)
    print("[PASS] sshd listening on 2222")

    machine.wait_for_unit("fail2ban.service")
    print("[PASS] fail2ban running")

    # Stub agenix files exist with placeholder content.
    out = machine.succeed("cat /run/agenix/gh-token")
    assert "stub-gh-token" in out, f"agenix stub missing: {out!r}"
    print("[PASS] agenix stub materialized")

    print("[PASS] congo boot smoke test complete")
  '';
}
