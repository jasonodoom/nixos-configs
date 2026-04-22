{ lib, ... }:

# Shell snippet that shadows the AI CLI entry points (claude/codex/gemini)
# with bash/zsh-compatible functions that auto-detect permission-bypass
# flags and color the Ghostty/iTerm tab for the life of the session.
#
# Detects these flags as "YOLO mode":
#   claude --dangerously-skip-permissions
#   codex  --dangerously-bypass-approvals-and-sandbox  (alias: --yolo)
#   gemini --yolo | -y
#
# Without a bypass flag, the functions just exec the real binary — no
# color change. OSC escapes pass through SSH and through tmux when
# `allow-passthrough on` is set, so the outer Ghostty tab tints even when
# the agent runs inside a microvm or a tmux pane.

{
  shellSnippet = ''
    __yolo_tab_on() {
      local label="$1"
      printf '\033]1337;SetColors=tabbg=f7768e\a'
      printf '\033]2;\xE2\x9A\xA0\xEF\xB8\x8F  YOLO: %s\007' "$label"
    }
    __yolo_tab_off() {
      printf '\033]1337;SetColors=tabbg=\a'
      printf '\033]2;\007'
    }
    __yolo_has_flag() {
      # $1 = label, $2.. = args from caller; echo "yolo" if any matches.
      local label="$1"; shift
      local a
      for a in "$@"; do
        case "$label:$a" in
          claude:--dangerously-skip-permissions) echo yolo; return ;;
          codex:--dangerously-bypass-approvals-and-sandbox|codex:--yolo) echo yolo; return ;;
          gemini:--yolo|gemini:-y) echo yolo; return ;;
        esac
      done
    }
    __yolo_wrap() {
      # $1 = label, $2 = real command to run (space-delimited, e.g.
      # "command claude" or "ssh -qt ai-claude claude"), $3.. = user args.
      local label="$1"; local cmd="$2"; shift 2
      if [ -n "$(__yolo_has_flag "$label" "$@")" ]; then
        __yolo_tab_on "$label"
        trap '__yolo_tab_off' EXIT INT TERM
        eval "$cmd" "$(printf ' %q' "$@")"
        local rc=$?
        __yolo_tab_off
        trap - EXIT INT TERM
        return $rc
      else
        eval "$cmd" "$(printf ' %q' "$@")"
      fi
    }
  '';
}
