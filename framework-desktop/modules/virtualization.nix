# Virtualization configuration
{ config, pkgs, lib, ... }:

{
  # Docker
  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  # Libvirt for QEMU/KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
    };
  };

  # VirtualBox (
  virtualisation.virtualbox.host = {
    enable = false;
    enableExtensionPack = false;
  };

  # Flatpak
  services.flatpak.enable = false;

  # Virtualization packages
  environment.systemPackages = with pkgs; [
    virt-manager
    docker-compose
  ];
}