{ config, lib, pkgs, ... }:

# Shared guest NixOS module used by both microvm-based (perdurabo) and
# systemd-nspawn-based (congo) AI agent sandboxes. Defines the unprivileged
# agent user, the CLI binary, and the loopback sshd the host uses to shell in.
#
# Options:
#   my.aiAgent.name     = string (e.g. "claude")
#   my.aiAgent.packages = list of CLI derivations
#   my.aiAgent.sshPort  = int, loopback port for host alias to connect to
#   my.aiAgent.hostPublicKeys = list of SSH pubkeys authorized to shell in

let
  cfg = config.my.aiAgent;

  # ~/peers is the shared parent ai-agents dir. A "_inbox" subdir there
  # acts as a message queue between the three guests: each ask writes
  # _inbox/<to>/<id>.json, the recipient's watcher invokes its local
  # CLI and drops _inbox/<from>/<id>.response.json.
  inboxDir = "/home/agent/peers/_inbox";

  askPeer = pkgs.writeShellScriptBin "ask-peer" ''
    set -eu
    if [ $# -lt 2 ]; then
      echo "usage: ask-peer <claude|codex|gemini> <prompt...>" >&2
      echo "       ask-peer <claude|codex> 'resume:<session-id> <prompt...>'" >&2
      exit 2
    fi
    to=$1; shift
    prompt="$*"
    self=$(${pkgs.inetutils}/bin/hostname | sed 's/^ai-//')

    ${pkgs.coreutils}/bin/mkdir -p "${inboxDir}/$to" "${inboxDir}/$self"

    id=$(${pkgs.util-linux}/bin/uuidgen)
    req="${inboxDir}/$to/$id.json"
    resp="${inboxDir}/$self/$id.response.json"

    ${pkgs.jq}/bin/jq -n \
      --arg id "$id" --arg from "$self" --arg to "$to" --arg p "$prompt" \
      '{id:$id, from:$from, to:$to, prompt:$p, created_at: (now|todate)}' \
      > "$req.tmp"
    ${pkgs.coreutils}/bin/mv "$req.tmp" "$req"

    for _ in $(seq 1 300); do
      if [ -f "$resp" ]; then
        ${pkgs.jq}/bin/jq -r '.response' "$resp"
        ${pkgs.coreutils}/bin/rm -f "$resp"
        exit 0
      fi
      sleep 1
    done
    echo "ask-peer: timeout waiting for $to" >&2
    exit 1
  '';

  inboxWatcher = pkgs.writeShellScriptBin "ai-peer-inbox-watcher" ''
    set -u
    self=$(${pkgs.inetutils}/bin/hostname | sed 's/^ai-//')
    my_inbox=${inboxDir}/$self
    ${pkgs.coreutils}/bin/mkdir -p "$my_inbox"

    # A prompt prefixed with "resume:<session-id> ..." continues that recorded
    # session instead of starting a fresh one. gemini has no resume concept,
    # so the prefix is stripped and ignored there.
    case "$self" in
      claude) invoke() {
        if [ -n "$1" ]; then claude --resume "$1" -p "$2" 2>&1
        else                  claude -p "$2" 2>&1
        fi
      } ;;
      codex)  invoke() {
        # --all disables codex's cwd-based session filter so sessions
        # recorded in any directory remain resumable from this daemon's
        # working dir (/home/agent).
        if [ -n "$1" ]; then codex exec resume --all "$1" "$2" 2>&1
        else                  codex exec "$2" 2>&1
        fi
      } ;;
      gemini) invoke() { gemini -p "$2" 2>&1; } ;;
      *) echo "unknown agent $self" >&2; exit 1 ;;
    esac

    process() {
      req=$1
      [ -f "$req" ] || return
      case "$req" in *.response.json|*.processing) return ;; esac

      processing="''${req%.json}.processing"
      ${pkgs.coreutils}/bin/mv "$req" "$processing" 2>/dev/null || return

      id=$(${pkgs.jq}/bin/jq -r '.id' "$processing")
      from=$(${pkgs.jq}/bin/jq -r '.from' "$processing")
      prompt=$(${pkgs.jq}/bin/jq -r '.prompt' "$processing")

      sid=""
      case "$prompt" in
        resume:*' '*)
          rest=''${prompt#resume:}
          sid=''${rest%% *}
          prompt=''${rest#* }
          ;;
      esac

      response=$(invoke "$sid" "$prompt" || true)

      out=${inboxDir}/$from
      ${pkgs.coreutils}/bin/mkdir -p "$out"
      ${pkgs.jq}/bin/jq -n \
        --arg id "$id" --arg from "$self" --arg to "$from" --arg r "$response" \
        '{id:$id, from:$from, to:$to, response:$r, created_at: (now|todate)}' \
        > "$out/$id.response.json.tmp"
      ${pkgs.coreutils}/bin/mv "$out/$id.response.json.tmp" "$out/$id.response.json"

      ${pkgs.coreutils}/bin/rm -f "$processing"
    }

    # Poll the inbox. inotify doesn't fire when the writer is on the other
    # side of a virtiofs (perdurabo) or bind mount (congo), so cross-vm
    # asks would queue forever waiting for an event that never arrives.
    while :; do
      for f in "$my_inbox"/*.json; do
        [ -e "$f" ] || continue
        process "$f"
      done
      sleep 2
    done
  '';
in
{
  options.my.aiAgent = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Short name for this agent (claude, codex, gemini).";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "CLI packages to install inside the guest.";
    };
    sshPort = lib.mkOption {
      type = lib.types.port;
      description = "Loopback port sshd listens on inside the guest.";
    };
    hostPublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys authorized to shell in as the agent user.";
    };
  };

  config = {
    users.mutableUsers = false;
    # Guest is only reachable via sshd with the host's pubkey. No interactive
    # login as root or any other user, so silence the "no password set" assert.
    users.allowNoPasswordLogin = true;

    users.users.agent = {
      isNormalUser = true;
      uid = 1000;
      home = "/home/agent";
      createHome = true;
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = cfg.hostPublicKeys;
    };

    users.groups.agent.gid = 1000;

    environment.systemPackages = cfg.packages ++ (with pkgs; [
      git
      curl
      jq
      ripgrep
      nodejs
      python3
      openssh
      gnupg
      gh
      # Editor + pager + modern coreutils
      vim
      less
      bat
      fd
      # JS / Cloudflare Workers stack
      wrangler
      bun
      direnv
      gnumake
      delta
      yq-go
      sqlite
      # Nix repo work
      agenix-cli
      nixpkgs-fmt
      alejandra
      # Shell quality-of-life
      httpie
      tldr
      ripgrep-all
      # Peer messaging
      askPeer
    ]);

    systemd.services.ai-peer-inbox-watcher = {
      description = "Watch peer inbox for messages from other AI agents";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = cfg.packages;
      serviceConfig = {
        Type = "simple";
        User = "agent";
        Group = "agent";
        ExecStart = "${inboxWatcher}/bin/ai-peer-inbox-watcher";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    # Required to run claude-code (Bun standalone) without patching it -
    # the binary's PT_INTERP is /lib64/ld-linux-x86-64.so.2 and patchelf
    # corrupts its embedded JS payload.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
      ];
    };

    # Stop claude-code's self-updater from downloading a parallel binary
    # into ~/.local/share/claude. nix owns the version here; if the user
    # wants a newer one they bump the overlay.
    environment.variables = {
      DISABLE_AUTOUPDATER = "1";
    };

    # claude-code still nags "Native installation exists but ~/.local/bin
    # is not in your PATH" on every startup even with the autoupdater off.
    # Putting the dir on PATH satisfies the check; it stays empty because
    # the autoupdater can't write to it.
    environment.sessionVariables = {
      PATH = [ "$HOME/.local/bin" ];
    };

    # OpenPGP signing with the key in ~/.gnupg is the default. SSH signing
    # is opt-in per-invocation when the host's ssh-agent is forwarded:
    #   git -c gpg.format=ssh -c user.signingkey=~/.ssh/signing-key.pub \
    #       commit -S -m ...
    environment.etc."gitconfig".text = ''
      [user]
        name = Jason Odoom
        email = jason@adastracomputing.com
        signingkey = A46573671D50E3D8
      [commit]
        gpgsign = true
      [tag]
        gpgsign = true
      [core]
        # Repo hooks are nix-store-pinned to whichever host ran
        # pre-commit install, so their shebangs are unusable here. Point
        # hooksPath at an empty dir to skip them; run pre-commit manually
        # before opening a PR.
        hooksPath = /var/empty
    '';

    services.openssh = {
      enable = true;
      ports = [ cfg.sshPort ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      listenAddresses = [
        { addr = "0.0.0.0"; port = cfg.sshPort; }
      ];
      # Persist sshd host keys on a bind-mounted path so they survive
      # VM/container rebuilds and clients don't see host-key-changed warnings.
      hostKeys = [
        { path = "/var/lib/sshd-hostkeys/ssh_host_ed25519_key"; type = "ed25519"; }
        { path = "/var/lib/sshd-hostkeys/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
      ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.sshPort ];

    time.timeZone = "UTC";
  };
}
