# Push AI agent histories and codex auth from theophany to perdurabo.
#
# claude project dirs are keyed by the absolute working directory the
# session was started in. /Users/jason/code/X on the Mac becomes
# /home/agent/code/X inside perdurabo's microvms, so the dir name has
# to be rewritten during sync or claude /resume in the guest can't
# find the session. Only ~/code projects are synced; sessions started
# in /Users/jason/Downloads, /private/tmp, etc. don't exist in the
# guest filesystem.
#
# codex is keyed by session id, not cwd, and the daemon passes --all
# to skip cwd filtering, so codex sessions sync verbatim.
#
# rsync is additive (no --delete) so anything the guest appended while
# running stays put.

{ config, pkgs, lib, ... }:

let
  syncScript = pkgs.writeShellScript "sync-ai-history" ''
    set -u
    LOG="$HOME/Library/Logs/sync-ai-history.log"
    exec >>"$LOG" 2>&1
    echo "[$(date '+%F %T')] start"

    REMOTE=perdurabo
    REMOTE_BASE=/home/jason/.local/state/ai-agents

    SSH="${pkgs.openssh}/bin/ssh \
      -o IdentityAgent=none \
      -o IdentitiesOnly=yes \
      -i $HOME/.ssh/id_ed25519 \
      -o BatchMode=yes \
      -o ConnectTimeout=5"

    if ! $SSH "$REMOTE" true 2>/dev/null; then
      echo "remote unreachable, skipping"
      exit 0
    fi

    # claude: iterate /Users/jason/code/* projects, rewrite encoded path.
    if [ -d "$HOME/.claude/projects" ]; then
      for dir in "$HOME"/.claude/projects/-Users-jason-code-*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")
        target="''${name/-Users-jason-code-/-home-agent-code-}"
        ${pkgs.rsync}/bin/rsync -a --partial -e "$SSH" \
          "$dir" "$REMOTE:$REMOTE_BASE/claude/.claude/projects/$target/"
      done
    fi

    sync() {
      src=$1; dst=$2
      [ -e "$src" ] || return 0
      ${pkgs.rsync}/bin/rsync -a --partial -e "$SSH" "$src" "$REMOTE:$dst"
    }

    sync "$HOME/.codex/sessions/"   "$REMOTE_BASE/codex/.codex/sessions/"
    sync "$HOME/.codex/auth.json"   "$REMOTE_BASE/codex/.codex/auth.json"
    sync "$HOME/.codex/config.toml" "$REMOTE_BASE/codex/.codex/config.toml"

    echo "[$(date '+%F %T')] done"
  '';
in
{
  launchd.user.agents.sync-ai-history = {
    serviceConfig = {
      ProgramArguments = [ "${syncScript}" ];
      StartInterval = 900;
      RunAtLoad = true;
      StandardOutPath = "/Users/jason/Library/Logs/sync-ai-history.out.log";
      StandardErrorPath = "/Users/jason/Library/Logs/sync-ai-history.err.log";
    };
  };
}
