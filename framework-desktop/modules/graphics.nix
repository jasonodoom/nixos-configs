# Graphics configuration for Framework Desktop (Radeon 8060S)
# - Framework Desktop specs: https://frame.work/products/desktop
# - AMD RDNA3 graphics: https://wiki.archlinux.org/title/AMDGPU
# - NixOS graphics: https://nixos.wiki/wiki/AMD_GPU
{ config, pkgs, lib, ... }:

{
  # Graphics configuration for Framework Desktop's Radeon 8060S iGPU (RDNA3)
  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkDefault true; # 32-bit support for gaming/legacy apps

    extraPackages = with pkgs; [
      mesa

      # Vulkan support
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools

      # AMD-specific packages for Framework Desktop's Radeon 8060S
      amdvlk                  # AMD's open-source Vulkan driver
      rocmPackages.clr.icd    # ROCm support for GPGPU computing workloads
    ];

    extraPackages32 = with pkgs; [
      # 32-bit drivers for gaming/legacy apps
      driversi686Linux.amdvlk
      driversi686Linux.mesa
    ];
  };

  # Framework Desktop graphics environment variables
  environment.variables = {
    # Wayland compositor optimization (helps with cursor rendering issues)
    WLR_NO_HARDWARE_CURSORS = "1";

    # AMD Radeon 8060S Graphics variables (Framework Desktop)
    # https://wiki.archlinux.org/title/AMDGPU#Vulkan
    AMD_VULKAN_ICD = "RADV";              # Use open-source RADV Vulkan driver

    # ROCm support for compute workloads (ML, cryptocurrency, etc.)
    # https://rocm.docs.amd.com/en/latest/
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # RDNA3 (gfx1100 series)
  };

}