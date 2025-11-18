{ config, pkgs, lib, ... }:

{
  # PAM (Pluggable Authentication Modules) configuration for macOS
  # Manages authentication methods for sudo and other system services

  # Enable Touch ID for sudo authentication
  # This allows you to use fingerprint instead of password for sudo commands
  # reattach enables Touch ID in tmux/screen/terminal multiplexers
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };
}
