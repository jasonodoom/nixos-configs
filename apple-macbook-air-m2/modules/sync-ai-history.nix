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
# --update so I don't overwrite a newer remote file with an older
# local one. --omit-dir-times so /recent's mtime sort isn't broken.
# No --delete, so guest-side appends survive.

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

    # claude: only the ai-claude microvm runs claude on perdurabo
    # (the host has no claude binary). Sync targets the microvm's
    # mounted home at /home/jason/.local/state/ai-agents/claude/.claude/.
    # Inside the microvm the same dir is at /home/agent/.claude/.
    #
    # Two encoded-path rewrites:
    #   -Users-jason-code-<X> → -home-agent-code-<X>   (subdir sessions)
    #   -Users-jason-code     → -home-agent-code       (bare ~/code sessions)
    # The earlier sync only handled the first case, so any session
    # started from /Users/jason/code itself never reached the microvm.
    if [ -d "$HOME/.claude/projects" ]; then
      for dir in "$HOME"/.claude/projects/-Users-jason-code-*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")
        target="''${name/-Users-jason-code-/-home-agent-code-}"
        ${pkgs.rsync}/bin/rsync -a --omit-dir-times --update --partial -e "$SSH" \
          "$dir/" "$REMOTE:$REMOTE_BASE/claude/.claude/projects/$target/" || true
      done
      bare="$HOME/.claude/projects/-Users-jason-code"
      if [ -d "$bare" ]; then
        ${pkgs.rsync}/bin/rsync -a --omit-dir-times --update --partial -e "$SSH" \
          "$bare/" "$REMOTE:$REMOTE_BASE/claude/.claude/projects/-home-agent-code/" || true
        # The bare ~/code sessions intentionally stay in their own
        # project dir on the remote. Previous versions of this script
        # also mirrored them into every per-project dir so claude
        # --resume from any subdir would find them, but that mixed
        # unrelated sessions into project listings (e.g. trace sessions
        # appearing in tulpa's /resume). To resume a bare-code session
        # from inside a subdir on the guest, cd back to ~/code first.
      fi

      # history.jsonl is the registry claude --resume actually uses
      # to scope sessions to projects. Sync it AND rewrite the
      # "project" field on the remote so /Users/jason/code paths
      # become /home/agent/code paths. Without this rewrite,
      # claude --resume <id> from a project dir says "no
      # conversation found" even when the .jsonl is in the right
      # project dir.
      if [ -f "$HOME/.claude/history.jsonl" ]; then
        ${pkgs.rsync}/bin/rsync -a --omit-dir-times --update --partial -e "$SSH" \
          "$HOME/.claude/history.jsonl" \
          "$REMOTE:$REMOTE_BASE/claude/.claude/history.jsonl" || true
        $SSH "$REMOTE" "${pkgs.gnused}/bin/sed -i 's|\"project\":\"/Users/jason/code\"|\"project\":\"/home/agent/code\"|g; s|\"project\":\"/Users/jason/code/|\"project\":\"/home/agent/code/|g' $REMOTE_BASE/claude/.claude/history.jsonl" || true
      fi
    fi

    sync() {
      src=$1; dst=$2
      [ -e "$src" ] || return 0
      ${pkgs.rsync}/bin/rsync -a --omit-dir-times --update --partial -e "$SSH" "$src" "$REMOTE:$dst"
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
