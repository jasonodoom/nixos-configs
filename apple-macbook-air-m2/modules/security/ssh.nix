{ config, pkgs, lib, ... }:

{
  # Add GitHub to known_hosts
  programs.ssh.knownHosts = {
    "github.com" = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };

  # SSH client configuration for theophany
  programs.ssh.extraConfig = ''
    # Deploy key for system operations (darwin-rebuild, etc.)
    Host github-deploy.com
      HostName github.com
      User git
      IdentityFile /etc/ssh/theophany_deploy_key
      IdentitiesOnly yes
      StrictHostKeyChecking yes

    # Adastra-org GitHub repos use an on-disk ed25519 key so autonomous
    # pushes don't require a YubiKey touch per commit.
    Host github-adastra.com
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_ed25519_adastra
      IdentitiesOnly yes
      StrictHostKeyChecking yes

    Host github.com
      HostName github.com
      PubkeyAuthentication yes
      IdentityFile ~/.ssh/id_rsa_yubikey.pub
      IdentitiesOnly yes
      User git

    Host perdurabo
      HostName perdurabo
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes
      # Forward gpg-agent's ssh socket (holds the YubiKey-backed identity)
      # so commits made inside perdurabo's AI-agent microvms can be signed
      # by the card that lives on this Mac.
      IdentityAgent ~/.gnupg/S.gpg-agent.ssh
      ForwardAgent yes

    Host congo
      HostName congo
      User amy
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes

    Host *
      Protocol 2
      HashKnownHosts yes
      PasswordAuthentication no
      StrictHostKeyChecking ask
      IdentityFile ~/.ssh/id_rsa_yubikey.pub
      IdentityFile ~/.ssh/id_ed25519
      VisualHostKey yes
      User jason
      LogLevel ERROR
  '';

  environment.systemPackages = with pkgs; [
    openssh
  ];

  # Per-host overrides pinned to the TOP of ~/.ssh/config. SSH uses
  # first-match-wins per keyword, and user config is read before system
  # config — so any `Host *` stanza later in the personal config (e.g.
  # `LogLevel DEBUG1`) would otherwise win for specific hosts like
  # perdurabo. Writing a managed block at position 1 beats it.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    USER_HOME="/Users/${config.system.primaryUser}"
    SSH_CFG="$USER_HOME/.ssh/config"
    MARKER_BEGIN="# BEGIN nix-darwin managed perdurabo overrides"
    MARKER_END="# END nix-darwin managed perdurabo overrides"

    mkdir -p "$USER_HOME/.ssh"
    touch "$SSH_CFG"
    chown ${config.system.primaryUser}:staff "$SSH_CFG"
    chmod 600 "$SSH_CFG"

    if ! grep -qF "$MARKER_BEGIN" "$SSH_CFG"; then
      tmp="$(mktemp)"
      {
        echo "$MARKER_BEGIN"
        echo "Host perdurabo ai-claude ai-codex ai-gemini"
        echo "  LogLevel ERROR"
        echo "$MARKER_END"
        echo ""
        cat "$SSH_CFG"
      } > "$tmp"
      mv "$tmp" "$SSH_CFG"
      chown ${config.system.primaryUser}:staff "$SSH_CFG"
      chmod 600 "$SSH_CFG"
    fi
  '';
}
