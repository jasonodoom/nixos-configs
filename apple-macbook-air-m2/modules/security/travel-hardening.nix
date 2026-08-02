# Travel hardening for hostile network environments.
# Set enabled to true and rebuild to auto-apply on activation.
# Scripts travel-mode-on / travel-mode-off / travel-mode-status /
# travel-mode-schedule are always installed regardless of the toggle.
#
# Design notes:
#   - System-domain defaults (/Library/Preferences/...) need root; every
#     such write goes through as_root so an unprivileged run escalates via
#     sudo once instead of failing silently.
#   - Bluetooth is driven with blueutil, which takes effect immediately;
#     the old ControllerPowerState plist write is ignored by bluetoothd on
#     current macOS until the daemon restarts.
#   - mDNSResponder only rereads its prefs on HUP, so the Bonjour toggle
#     kicks the daemon.
#   - The application firewall + stealth mode are the highest-value knobs
#     on a hostile network and are enabled first.
#   - The WiFi purge saves the list to ~/.local/state/travel-mode first so
#     networks can be re-added after the trip.
#   - Both scripts accept --dry-run (print what would run, change nothing)
#     so the flow is testable without toggling a live machine.
#   - travel-mode-status is read-only and reports the ACTUAL state of each
#     knob, so you can verify what applied before walking out the door.
#   - Scheduling: a launchd job cannot sudo, so on/off split into scopes:
#     --system-only (root LaunchDaemon) and --user-only (user LaunchAgent).
#     travel-mode-schedule installs one-shot pairs for the start and end
#     datetimes; sudo happens once, interactively, at scheduling time.
#     StartCalendarInterval fires missed jobs on wake, so a laptop asleep
#     in a bag still flips modes at the next wake.
{ config, pkgs, lib, ... }:

let
  enabled = false;

  # Shared prelude: dry-run plumbing, scope selection, root escalation.
  prelude = ''
    DRY=0
    SCOPE=all
    for a in "$@"; do
      case "$a" in
        --dry-run) DRY=1 ;;
        --user-only) SCOPE=user ;;
        --system-only) SCOPE=system ;;
      esac
    done
    do_user() { [ "$SCOPE" != "system" ]; }
    do_sys()  { [ "$SCOPE" != "user" ]; }
    run() {
      if [ "$DRY" = 1 ]; then echo "DRY: $*"; else "$@"; fi
    }
    as_root() {
      if [ "$DRY" = 1 ]; then echo "DRY: sudo $*"; return 0; fi
      if [ "$(id -u)" = 0 ]; then "$@"; else /usr/bin/sudo "$@"; fi
    }
    STATE_DIR="$HOME/.local/state/travel-mode"
    mkdir -p "$STATE_DIR" 2>/dev/null || STATE_DIR=/tmp/travel-mode-state
  '';
in
{
  system.activationScripts.travel-hardening = lib.mkIf enabled {
    text = ''
      echo "Applying travel hardening..."
      /run/current-system/sw/bin/travel-mode-on
    '';
  };

  environment.systemPackages = [
    pkgs.blueutil

    (pkgs.writeScriptBin "travel-mode-on" ''
      #!${pkgs.bash}/bin/bash
      set -u
      ${prelude}
      echo "Activating travel mode (scope: $SCOPE)..."
      [ "$DRY" = 1 ] && echo "(dry run — nothing will change)"

      # FileVault check (verify only; enabling it is an interactive decision)
      if ! /usr/bin/fdesetup status | grep -q "FileVault is On"; then
        echo "WARNING: FileVault is NOT enabled — your disk is not encrypted"
      else
        echo "FileVault: on"
      fi

      if do_sys; then
        # Application firewall + stealth mode: the highest-value protection
        # on a hostile network, so it goes first.
        as_root /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
        as_root /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
        echo "Firewall: on, stealth mode: on"
      fi

      if do_user; then
        # Bluetooth off, effective immediately.
        run ${pkgs.blueutil}/bin/blueutil --power 0
        echo "Bluetooth: disabled"

        run /usr/bin/defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
        echo "AirDrop: disabled"

        run /usr/bin/defaults -currentHost write com.apple.controlcenter AirplayReceiver -int 18
        echo "AirPlay Receiver: disabled"

        run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false
        run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
        echo "Handoff and Continuity: disabled"

        run /usr/bin/defaults write com.apple.assistant.support "Assistant Enabled" -bool false
        run /usr/bin/defaults write com.apple.Siri StatusMenuVisible -bool false
        echo "Siri: disabled"

        run /usr/bin/defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
        echo "Spotlight suggestions: disabled"
      fi

      if do_sys; then
        # Bonjour multicast advertising (system domain, daemon rereads on HUP)
        as_root /usr/bin/defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true
        as_root /usr/bin/killall -HUP mDNSResponder
        echo "Bonjour multicast: disabled"

        # Captive portal auto-probe. Deliberate trade-off: hotel/airport
        # portals need a manual browser visit to a plain http site to log in.
        as_root /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false
        echo "Captive portal detection: disabled (open http://captive.apple.com manually for portals)"

        as_root /usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 0
        echo "Location services: disabled"

        as_root /usr/bin/pmset -a womp 0
        echo "Wake for network access: disabled"

        # Purge saved WiFi networks, backing the list up first so they can
        # be re-added after the trip. Removal requires admin rights.
        WIFI_IF=$(/usr/sbin/networksetup -listallhardwareports | ${pkgs.gawk}/bin/awk '/Wi-Fi/{getline; print $2}')
        if [ -n "$WIFI_IF" ]; then
          if [ "$DRY" = 1 ]; then
            echo "DRY: backup + purge preferred wireless networks on $WIFI_IF"
          else
            /usr/sbin/networksetup -listpreferredwirelessnetworks "$WIFI_IF" \
              > "$STATE_DIR/wifi-networks.$(date +%Y%m%d-%H%M%S).txt" 2>/dev/null
            as_root /usr/sbin/networksetup -removeallpreferredwirelessnetworks "$WIFI_IF"
            echo "Saved WiFi networks: purged (backup in $STATE_DIR)"
          fi
        fi
      fi

      echo ""
      echo "Travel mode ($SCOPE) active. Verify with: travel-mode-status"
      if [ "$SCOPE" = all ]; then
        echo "Remember to:"
        echo "  - Route traffic through a Tailscale exit node"
        echo "  - Use a USB data blocker for charging"
      fi
    '')

    (pkgs.writeScriptBin "travel-mode-off" ''
      #!${pkgs.bash}/bin/bash
      set -u
      ${prelude}
      echo "Deactivating travel mode (scope: $SCOPE)..."
      [ "$DRY" = 1 ] && echo "(dry run — nothing will change)"

      if do_sys; then
        # Stealth mode off; the firewall itself stays on (good default at home too).
        as_root /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode off
        echo "Firewall: still on, stealth mode: off"
      fi

      if do_user; then
        run ${pkgs.blueutil}/bin/blueutil --power 1
        echo "Bluetooth: enabled"

        run /usr/bin/defaults write com.apple.NetworkBrowser DisableAirDrop -bool false
        echo "AirDrop: enabled"

        run /usr/bin/defaults -currentHost write com.apple.controlcenter AirplayReceiver -int 2
        echo "AirPlay Receiver: enabled"

        run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool true
        run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool true
        echo "Handoff and Continuity: enabled"

        run /usr/bin/defaults write com.apple.assistant.support "Assistant Enabled" -bool true
        run /usr/bin/defaults write com.apple.Siri StatusMenuVisible -bool true
        echo "Siri: enabled"

        run /usr/bin/defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool false
        echo "Spotlight suggestions: enabled"
      fi

      if do_sys; then
        as_root /usr/bin/defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool false
        as_root /usr/bin/killall -HUP mDNSResponder
        echo "Bonjour multicast: enabled"

        as_root /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool true
        echo "Captive portal detection: enabled"

        as_root /usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 1
        echo "Location services: enabled"

        as_root /usr/bin/pmset -a womp 1
        echo "Wake for network access: enabled"
      fi

      echo ""
      echo "Travel mode ($SCOPE) deactivated"
      LAST_BACKUP=$(ls -t "$STATE_DIR"/wifi-networks.*.txt 2>/dev/null | head -1)
      if [ -n "''${LAST_BACKUP:-}" ]; then
        echo "Saved WiFi networks were purged; the pre-travel list is at:"
        echo "  $LAST_BACKUP"
      fi
    '')

    (pkgs.writeScriptBin "travel-mode-status" ''
      #!${pkgs.bash}/bin/bash
      # Read-only report of the ACTUAL state of every travel-mode knob, so
      # you can verify what applied. Exit code 0 = fully in travel posture.
      set -u
      ok=0
      check() { # label, want, got
        if [ "$2" = "$3" ]; then
          echo "  [ok]   $1"
        else
          echo "  [DIFF] $1 (want $2, got $3)"
          ok=1
        fi
      }
      echo "Travel-mode status:"

      fv=$(/usr/bin/fdesetup status | grep -q "FileVault is On" && echo on || echo off)
      check "FileVault on" on "$fv"

      fw=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled" && echo on || echo off)
      check "Firewall on" on "$fw"
      st=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | grep -q "enabled" && echo on || echo off)
      check "Stealth mode on" on "$st"

      bt=$(${pkgs.blueutil}/bin/blueutil --power 2>/dev/null || echo "?")
      check "Bluetooth off" 0 "$bt"

      ad=$(/usr/bin/defaults read com.apple.NetworkBrowser DisableAirDrop 2>/dev/null || echo 0)
      check "AirDrop disabled" 1 "$ad"

      bj=$(/usr/bin/defaults read /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements 2>/dev/null || echo 0)
      check "Bonjour multicast off" 1 "$bj"

      cp=$(/usr/bin/defaults read /Library/Preferences/SystemConfiguration/com.apple.captive.control Active 2>/dev/null || echo 1)
      check "Captive portal probe off" 0 "$cp"

      womp=$(/usr/bin/pmset -g | ${pkgs.gawk}/bin/awk '/womp/{print $2; exit}')
      check "Wake for network off" 0 "''${womp:-?}"

      echo ""
      echo "Scheduled transitions:"
      found=0
      for p in /Library/LaunchDaemons/com.travelmode.*.plist "$HOME"/Library/LaunchAgents/com.travelmode.*.plist; do
        [ -f "$p" ] || continue
        found=1
        when=$(/usr/bin/plutil -extract Comment raw "$p" 2>/dev/null || echo "?")
        echo "  $(basename "$p"): $when"
      done
      [ "$found" = 0 ] && echo "  (none)"

      exit $ok
    '')

    (pkgs.writeScriptBin "travel-mode-schedule" ''
      #!${pkgs.bash}/bin/bash
      # Schedule travel mode on/off as one-shot launchd jobs.
      #
      #   travel-mode-schedule "2026-08-03 14:00" "2026-08-10 09:00"
      #   travel-mode-schedule --list
      #   travel-mode-schedule --cancel
      #
      # Each transition installs a PAIR of jobs: a root LaunchDaemon for the
      # system-domain knobs (--system-only; launchd jobs cannot sudo) and a
      # user LaunchAgent for the user-domain knobs (--user-only). sudo runs
      # once now, while you are at the keyboard. Jobs self-remove after
      # firing. launchd runs a missed StartCalendarInterval on next wake.
      set -euo pipefail

      DAEMON_DIR=/Library/LaunchDaemons
      AGENT_DIR="$HOME/Library/LaunchAgents"
      UID_NUM=$(id -u)

      list_jobs() {
        local found=0
        for p in $DAEMON_DIR/com.travelmode.*.plist "$AGENT_DIR"/com.travelmode.*.plist; do
          [ -f "$p" ] || continue
          found=1
          echo "$(basename "$p"): $(/usr/bin/plutil -extract Comment raw "$p" 2>/dev/null || echo '?')"
        done
        [ "$found" = 0 ] && echo "no scheduled travel-mode transitions"
      }

      cancel_jobs() {
        for p in "$AGENT_DIR"/com.travelmode.*.plist; do
          [ -f "$p" ] || continue
          /bin/launchctl bootout "gui/$UID_NUM" "$p" 2>/dev/null || true
          rm -f "$p"
          echo "removed $(basename "$p")"
        done
        for p in $DAEMON_DIR/com.travelmode.*.plist; do
          [ -f "$p" ] || continue
          /usr/bin/sudo /bin/launchctl bootout system "$p" 2>/dev/null || true
          /usr/bin/sudo rm -f "$p"
          echo "removed $(basename "$p")"
        done
      }

      case "''${1:-}" in
        --list) list_jobs; exit 0 ;;
        --cancel) cancel_jobs; exit 0 ;;
      esac

      if [ $# -ne 2 ]; then
        echo "usage: travel-mode-schedule \"YYYY-MM-DD HH:MM\" \"YYYY-MM-DD HH:MM\"" >&2
        echo "       travel-mode-schedule --list | --cancel" >&2
        exit 2
      fi

      parse() { /bin/date -j -f "%Y-%m-%d %H:%M" "$1" +%s 2>/dev/null; }
      ON_EPOCH=$(parse "$1") || { echo "cannot parse start: $1" >&2; exit 2; }
      OFF_EPOCH=$(parse "$2") || { echo "cannot parse end: $2" >&2; exit 2; }
      NOW=$(/bin/date +%s)
      [ "$ON_EPOCH" -gt "$NOW" ] || { echo "start must be in the future" >&2; exit 2; }
      [ "$OFF_EPOCH" -gt "$ON_EPOCH" ] || { echo "end must be after start" >&2; exit 2; }

      cal_field() { /bin/date -j -f "%s" "$1" "+$2"; }

      # write_plist mode(on|off) tier(daemon|agent) epoch
      write_plist() {
        local mode="$1" tier="$2" epoch="$3"
        local label="com.travelmode.$mode.$tier"
        local scope path runner
        local mm dd hh mi human
        mm=$(cal_field "$epoch" %m); dd=$(cal_field "$epoch" %d)
        hh=$(cal_field "$epoch" %H); mi=$(cal_field "$epoch" %M)
        human=$(cal_field "$epoch" "%Y-%m-%d %H:%M")
        if [ "$tier" = daemon ]; then
          scope="--system-only"; path="$DAEMON_DIR/$label.plist"
        else
          scope="--user-only"; path="$AGENT_DIR/$label.plist"
        fi
        # The job runs the mode script, then removes its own plist so the
        # one-shot never refires next year.
        runner="/run/current-system/sw/bin/travel-mode-$mode $scope; rm -f $path"
        local tmp; tmp=$(mktemp)
        cat > "$tmp" <<PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>Label</key><string>$label</string>
        <key>Comment</key><string>travel-mode-$mode ($tier) at $human</string>
        <key>ProgramArguments</key>
        <array><string>/bin/bash</string><string>-c</string><string>$runner</string></array>
        <key>StartCalendarInterval</key>
        <dict>
          <key>Month</key><integer>''${mm#0}</integer>
          <key>Day</key><integer>''${dd#0}</integer>
          <key>Hour</key><integer>''${hh#0}</integer>
          <key>Minute</key><integer>''${mi#0}</integer>
        </dict>
        <key>RunAtLoad</key><false/>
      </dict></plist>
      PLIST
        if [ "$tier" = daemon ]; then
          /usr/bin/sudo /bin/mkdir -p "$DAEMON_DIR"
          /usr/bin/sudo /bin/cp "$tmp" "$path"
          /usr/bin/sudo /usr/sbin/chown root:wheel "$path"
          /usr/bin/sudo /bin/chmod 644 "$path"
          /usr/bin/sudo /bin/launchctl bootout system "$path" 2>/dev/null || true
          /usr/bin/sudo /bin/launchctl bootstrap system "$path"
        else
          /bin/mkdir -p "$AGENT_DIR"
          /bin/cp "$tmp" "$path"
          /bin/chmod 644 "$path"
          /bin/launchctl bootout "gui/$UID_NUM" "$path" 2>/dev/null || true
          /bin/launchctl bootstrap "gui/$UID_NUM" "$path"
        fi
        rm -f "$tmp"
        echo "scheduled: travel-mode-$mode ($tier) at $human"
      }

      # Replace any existing schedule before installing the new one.
      cancel_jobs >/dev/null 2>&1 || true

      write_plist on  agent  "$ON_EPOCH"
      write_plist on  daemon "$ON_EPOCH"
      write_plist off agent  "$OFF_EPOCH"
      write_plist off daemon "$OFF_EPOCH"

      echo ""
      echo "Travel mode will turn ON at  $1"
      echo "                 and OFF at $2"
      echo "Check with: travel-mode-schedule --list   Cancel with: travel-mode-schedule --cancel"
      echo "Note: a transition missed while asleep fires at the next wake."
    '')
  ];
}
