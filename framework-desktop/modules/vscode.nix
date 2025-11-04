# VS Code configuration and packages
{ config, pkgs, lib, system, ... }:

{
  # Install VS Code and related packages
  environment.systemPackages = with pkgs; [
    vscode

    # VS Code extensions 
    (vscode-with-extensions.override {
      vscode = vscode;
      vscodeExtensions = with vscode-extensions; [
        # Nix ecosystem
        bbenoist.nix
        jnoortheen.nix-ide

        # Development tools
        eamodio.gitlens
        github.copilot
        github.copilot-chat
        github.vscode-github-actions
        ms-vsliveshare.vsliveshare
        editorconfig.editorconfig
        mkhl.direnv

        # Docker and containers
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit


        # Code quality and formatting
        davidanson.vscode-markdownlint
        esbenp.prettier-vscode

        # Build tools
        ms-vscode.makefile-tools
      ];
    })

    # System-level language support (Nix only)
    nil              # Nix language server
    nixfmt-tree   # Nix formatter

  ];
}