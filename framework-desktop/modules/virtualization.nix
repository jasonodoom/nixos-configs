# Virtualization configuration
{ config, pkgs, lib, ... }:

{
  # Docker
  virtualisation.docker = {
    enable = true;
    liveRestore = false;
  };

  # Libvirt for QEMU/KVM (OVMF/UEFI available by default)
  virtualisation.libvirtd.enable = true;

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
