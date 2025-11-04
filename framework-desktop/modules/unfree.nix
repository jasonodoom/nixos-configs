# Unfree package configuration
{ config, pkgs, lib, ... }:

{
  # Allow specific unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    # Development tools
    "vscode"
    "vscode-with-extensions"
    "postman"

    # VS Code extensions
    "vscode-extension-github-copilot"
    "vscode-extension-github-copilot-chat"
    "vscode-extension-ms-vsliveshare-vsliveshare"
    "vscode-extension-ms-vscode-remote-remote-containers"
    "vscode-extension-ms-vscode-remote-remote-ssh"
    "vscode-extension-ms-vscode-remote-remote-ssh-edit"
    "vscode-extension-ms-azuretools-vscode-docker"

    # Claude Code overlay
    "claude-code"

    # Browsers
    "google-chrome"

    # Gaming
    "steam"
    "steam-original"
    "steam-runtime"
    "steam-run-native"
    "steam-unwrapped"

    # Communication
    "discord"
    "slack"

    # Media
    "cider"

    # Virtualization
    "vagrant"

    # Security tools
    "burpsuite"

    # DevOps tools
    "terraform"
  ];
}