# Boot test: import the same modules perdurabo uses, override what QEMU can't
# do (LUKS, real tailscale auth, hardware-specific settings, real agenix
# secrets), boot the VM, and assert that multi-user.target plus key services
# come up.
#
# This catches userspace boot regressions: bad unit ordering, broken services,
# package set conflicts. It does NOT exercise LUKS unlock over SSH or the
# tailscale-initrd handshake; those need a real disk image and control plane
# and are covered structurally by the initrd-unlock test.
{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

pkgs.testers.nixosTest {
  name = "perdurabo-boot-test";

  nodes.machine = { config, pkgs, lib, modulesPath, ... }: {
    imports = [
      ./lib/age-stub.nix
      ../modules/bash/bash.nix
      ../modules/network/networking.nix
      ../modules/security/security.nix
      ../modules/security/secrets.nix
      ../modules/security/ssh.nix
      ../modules/services/verify-commits.nix
      ../modules/user-config.nix
    ];

    virtualisation = {
      memorySize = 2048;
      cores = 2;
      diskSize = 4096;
      qemu.options = [ "-display none" ];
    };

    boot.initrd.luks.devices = lib.mkForce {};
    boot.initrd.systemd.enable = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    services.tailscale.enable = lib.mkForce false;

    networking.networkmanager.enable = lib.mkForce false;
    networking.useDHCP = lib.mkForce true;
    networking.firewall.interfaces = lib.mkForce {};

    # Mask network-dependent oneshots so the test doesn't try to clone the
    # repo or touch the GitHub API.
    systemd.services.verify-upgrade-commits.wantedBy = lib.mkForce [];
    systemd.services.import-gpg-key.wantedBy = lib.mkForce [];

    system.stateVersion = "25.05";
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")
    print("[PASS] multi-user.target reached")

    machine.wait_for_unit("sshd.service")
    machine.wait_for_open_port(6666)
    print("[PASS] sshd listening on 6666")

    out = machine.succeed("cat /run/agenix/jason-password")
    assert "stub-jason-password" in out, f"agenix stub missing: {out!r}"
    print("[PASS] agenix stub materialized")

    print("[PASS] perdurabo boot smoke test complete")
  '';
}
