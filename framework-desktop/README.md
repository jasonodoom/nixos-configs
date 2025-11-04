# NixOS Configuration for Framework Desktop

This is a NixOS configuration written specifically for the Framework Desktop Max+ 395 (16-core/32-thread, 64GB RAM, Radeon 8060S Graphics) with Hyprland window manager.

## Table of Contents

- [Features](#features)
- [Structure](#structure)
- [Development Shells](#development-shells)
- [Installation](#installation)
  - [Partition and Format Drives (LUKS + LVM Setup)](#partition-and-format-drives-luks--lvm-setup)
  - [Prepare the System](#prepare-the-system)
  - [Generate Hardware Configuration](#generate-hardware-configuration)
  - [Install NixOS](#install-nixos)
  - [Post-Installation](#post-installation)
- [YubiKey Authentication](#yubikey-authentication)
- [Testing](#testing)
- [Customization](#customization)
- [Updates](#updates)

## Features

- **Framework Desktop Max+ 395 optimized**: Specific hardware configurations for 16-core Ryzen 7, Radeon 8060S
- **Hyprland**: Modern Wayland compositor with Tokyo Night theme and dual monitor support
- **Desktop performance**: Optimized for performance over power savings (desktop workstation)
- **Development shells**: Isolated environments for Go, Python, Node.js, Rust and DevOps using flake-utils
- **Clean system**: Languages and dev tools in project-specific shells, not globally installed
- **Modular structure**: Easy to customize and maintain
- **Flake-based**: Reproducible builds and dependency management
- **Pure NixOS**: No Home Manager dependency, everything in standard NixOS modules
- **VS Code ready**: Extensions and language servers available via development shells
- **Security focused**: Automated YubiKey challenge-response setup, doas instead of sudo, encrypted storage
- **Complete shell environment**: Bash/zsh with git configuration and SSH setup

## Structure

``` bash
.
├── flake.nix                   # Main flake configuration with flake-utils
├── configuration.nix           # Main system configuration
├── hardware-configuration.nix  # Hardware-specific settings 
├── overlays/                   # Custom package overlays
│   ├── default.nix             # Main overlay aggregator
│   └── claude-code.nix         # Claude Code specific overlay 
└── modules/
    ├── applications.nix       # Desktop applications
    ├── audio.nix              # Audio system (PipeWire)
    ├── bluetooth.nix          # Bluetooth configuration
    ├── development.nix        # System development tools (no languages)
    ├── gaming.nix             # Gaming setup 
    ├── graphics.nix           # AMD graphics configuration
    ├── hyprland.nix           # Hyprland window manager + Tokyo Night theme
    ├── networking.nix         # Network and SSH configuration
    ├── security.nix           # Security configuration
    ├── system.nix             # Core system settings
    ├── unfree.nix             # Centralized unfree package management
    ├── user-config.nix        # Complete user environment (git, ssh, bash/zsh)
    ├── virtualization.nix     # Docker and VM support
    └── vscode.nix             # VS Code with general extensions
```

## Development Shells

This configuration includes isolated development environments:

- **Go**: `nix develop .#go` - go, gopls, gofumpt, golangci-lint, delve
- **Python**: `nix develop .#python` - python3, pyright, black, isort, pylint, pytest
- **Node.js**: `nix develop .#node` - nodejs, typescript, ts-server, prettier, eslint
- **Rust**: `nix develop .#rust` - rustc, cargo, rust-analyzer, rustfmt, clippy
- **DevOps**: `nix develop .#devops` - terraform, ansible, ansible-lint, kubectl, k9s, kustomize, docker-compose, helm, awscli2, eksctl

## Installation

Partitioning guide adapted from [QFPL's Installing NixOS guide](https://qfpl.io/posts/installing-nixos/).

### Partition and Format Drives (LUKS + LVM Setup)

This setup uses LUKS full-disk encryption with LVM.

#### Create Partitions

```bash
# Partition the NVMe drive
sudo fdisk /dev/nvme0n1

# Create GPT partition table (type 'g')
# Create partitions:
# Partition 1: EFI System (5GB, type 1)
#   First sector: 2048
#   Last sector: +5G
# Partition 2: Linux LVM (remaining space, type 30)
#   First sector: (default)
#   Last sector: (default - use remaining space)

# Write changes (type 'w')
```

Expected partition layout:

```bash
Device            Start        End    Sectors   Size Type
/dev/nvme0n1p1     2048   10487807   10485760     5G EFI System
/dev/nvme0n1p2 10487808 1953523711 1943035904 926.5G Linux LVM
```

#### Setup LUKS Encryption

```bash
# Format the EFI boot partition
sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1

# Setup LUKS encryption on the main partition
sudo cryptsetup luksFormat /dev/nvme0n1p2

# Open the encrypted partition
sudo cryptsetup luksOpen /dev/nvme0n1p2 nixos-enc
```

#### etup LVM

```bash
# Create physical volume
sudo pvcreate /dev/mapper/nixos-enc

# Create volume group
sudo vgcreate nixos-vg /dev/mapper/nixos-enc

# Create logical volumes
sudo lvcreate -L 16G -n swap nixos-vg      
sudo lvcreate -l 100%FREE -n root nixos-vg

# Format filesystems
sudo mkfs.ext4 /dev/mapper/nixos--vg-root
sudo mkswap /dev/mapper/nixos--vg-swap
```

#### Mount Filesystems

```bash
# Mount root filesystem
sudo mount /dev/mapper/nixos--vg-root /mnt

# Create and mount boot directory
sudo mkdir /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot

# Enable swap
sudo swapon /dev/mapper/nixos--vg-swap
```

#### Verify Setup

```bash
# Check the partition layout
lsblk

# Expected output:
# nvme0n1              259:0    0 931.5G  0 disk
# ├─nvme0n1p1          259:1    0     5G  0 part  /mnt/boot
# └─nvme0n1p2          259:4    0 926.5G  0 part
#   └─nixos-enc        254:0    0 926.5G  0 crypt
#     ├─nixos--vg-swap 254:1    0    16G  0 lvm   [SWAP]
#     └─nixos--vg-root 254:2    0 910.5G  0 lvm   /mnt
```

### Prepare the System

```bash
# Enable flakes temporarily
nix --experimental-features "nix-command flakes" shell nixpkgs#git

# Clone this configuration
git clone https://github.com/jasonodoom/nixos-configs /mnt/etc/nixos
cd /mnt/etc/nixos/framework-desktop
```

### Generate Hardware Configuration

Only follow this step on new hardware or when hardware-configuration.nix does not match.
Update **hardware-configuration.nix**: Replace the values with actual UUIDs from the generated file.

```bash
# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# Copy the generated hardware-configuration.nix if needed
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-configs
```

> This configuration requires the correct LUKS setup in hardware-configuration.nix:

```nix
> 
> boot.initrd.luks.devices."nixos-enc" = {
>   device = "/dev/nvme0n1p2";
>   preLVM = true;  # decrypt before LVM
> };
```

### Install NixOS

```bash
# Install with flakes (Framework Desktop)
sudo nixos-install --flake .#perdurabo

# Set password for jason user
sudo nixos-enter --root /mnt
passwd jason
exit

# Reboot
sudo reboot
```

### Post-Installation

After rebooting into your new system:

```bash
# Build and switch to the configuration
sudo nixos-rebuild switch --flake .#perdurabo

# Update flake inputs
nix flake update

# All user configurations are part of the system rebuild
```

## YubiKey Authentication

This configuration includes automated YubiKey challenge-response authentication setup.

### Features

- **Automated setup**: YubiKey challenge-response mapping is created automatically on first boot
- **Multi-service support**: Enabled for login, doas (sudo replacement) and SDDM display manager
- **Hardware-specific**: Pre-configured for YubiKey serial 5252959
- **Secure permissions**: Challenge files are automatically secured with proper ownership and permissions

### How It Works

1. **Systemd service**: `yubikey-setup.service` runs on first boot
2. **Challenge-response mapping**: Creates `/etc/yubico/challenge-5252959` using `ykpamcfg`
3. **PAM integration**: Enables YubiKey authentication for:
   - System login
   - SDDM display manager
   - doas commands

### Manual Setup (if needed)

If automatic setup fails, you can manually configure:

```bash
# Create yubico directory
sudo mkdir -p /etc/yubico

# Set up challenge-response (YubiKey must be plugged in)
sudo ykpamcfg -2 -v

# Set proper permissions
sudo chmod 600 /etc/yubico/challenge-*
sudo chown root:root /etc/yubico/challenge-*
```

### Usage

- **Login**: Enter your password, then touch the YubiKey when it blinks
- **doas commands**: Same process for elevated privileges
- **Display manager**: YubiKey authentication at the login screen

### Troubleshooting

- Ensure YubiKey is plugged in during setup
- Check service status: `systemctl status yubikey-setup.service`
- View logs: `journalctl -u yubikey-setup.service`
- Verify mapping file exists: `ls -la /etc/yubico/`

## Testing

Test the flake configuration:

```bash
nix flake check
```

Test building the configuration:

```bash
sudo nixos-rebuild test --flake .#perdurabo
```

Test development shells:

```bash
nix develop .#go
nix develop .#python
nix develop .#devops
```

## Customization

### Adding/Removing Applications

Edit `modules/applications.nix` to add or remove system-wide applications.

### Framework Hardware Adjustments

The configuration should work out of the box with Framework Desktop Max+ 395, but you may need to adjust:

- **Monitor configuration** in `modules/hyprland.nix`
- **Hardware-specific options** in `hardware-configuration.nix`
- **CPU performance** settings in `hardware-configuration.nix` (set to "performance" for desktop workstation)
- **Framework-specific packages** in `modules/unfree.nix` and `modules/applications.nix`

## Updates

### Manual Updates

To update the system manually:

```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#perdurabo
```

### Automatic Updates

<https://nixos.wiki/wiki/Automatic_system_upgrades>

Automatic updates are **enabled** and will pull daily from `github:jasonodoom/nixos-configs`.

```bash
# Check auto-upgrade status
sudo systemctl status nixos-upgrade.timer

# View recent upgrade logs
journalctl -u nixos-upgrade.service

# Manually trigger an upgrade
sudo systemctl start nixos-upgrade.service
```

To disable automatic updates, set `system.autoUpgrade.enable = false` in `modules/system.nix`.
