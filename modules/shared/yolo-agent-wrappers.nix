{ lib, ... }:

# Shared shell snippet that defines wrappers around AI CLIs when invoked
# with permission bypass flags. The wrapper:
#   - sets the Ghostty/iTerm-style tab background color (OSC 1337 SetColors)
#   - prefixes the terminal tab title with a warning glyph (OSC 2)
#   - restores both on exit (trap)
#
# Exposes three functions: yolo-claude / yolo-codex / yolo-gemini.
# Use the exported string via programs.{bash,zsh}.interactiveShellInit.

{
  shellSnippet = ''
    # Emit Ghostty/iTerm2 tab-bg color + tab-title. OSC sequences pass
    # through SSH, so running this wrapper on perdurabo also colors the
    # Ghostty tab on theophany.
    __yolo_tab_on() {
      local label="$1"
      # iTerm2/Ghostty: tab background color (red-ish)
      printf '\033]1337;SetColors=tabbg=f7768e\a'
      # Window/tab title prefix
      printf '\033]2;\xE2\x9A\xA0\xEF\xB8\x8F  YOLO: %s\007' "$label"
    }
    __yolo_tab_off() {
      printf '\033]1337;SetColors=tabbg=\a'
      printf '\033]2;\007'
    }
    __yolo_run() {
      local label="$1"; shift
      __yolo_tab_on "$label"
      trap '__yolo_tab_off' EXIT INT TERM
      "$@"
      local rc=$?
      __yolo_tab_off
      trap - EXIT INT TERM
      return $rc
    }

    yolo-claude() { __yolo_run claude claude --dangerously-skip-permissions "$@"; }
    yolo-codex()  { __yolo_run codex  codex  --dangerously-bypass-approvals-and-sandbox "$@"; }
    yolo-gemini() { __yolo_run gemini gemini --yolo "$@"; }
  '';
}
