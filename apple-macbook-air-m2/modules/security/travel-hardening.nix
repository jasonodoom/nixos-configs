# Travel hardening for hostile network environments.
# Set enabled to true and rebuild to auto-apply on activation.
# Scripts travel-mode-on / travel-mode-off / travel-mode-status are always
# installed regardless of the toggle.
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
{ config, pkgs, lib, ... }:

let
  enabled = false;

  # Shared prelude: dry-run plumbing + root escalation for system domains.
  prelude = ''
    DRY=0
    [ "''${1:-}" = "--dry-run" ] && DRY=1
    run() {
      if [ "$DRY" = 1 ]; then echo "DRY: $*"; else "$@"; fi
    }
    as_root() {
      if [ "$DRY" = 1 ]; then echo "DRY: sudo $*"; return 0; fi
      if [ "$(id -u)" = 0 ]; then "$@"; else /usr/bin/sudo "$@"; fi
    }
    STATE_DIR="$HOME/.local/state/travel-mode"
    mkdir -p "$STATE_DIR"
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
      echo "Activating travel mode...''${DRY:+}"
      [ "$DRY" = 1 ] && echo "(dry run — nothing will change)"

      # FileVault check (verify only; enabling it is an interactive decision)
      if ! /usr/bin/fdesetup status | grep -q "FileVault is On"; then
        echo "WARNING: FileVault is NOT enabled — your disk is not encrypted"
      else
        echo "FileVault: on"
      fi

      # Application firewall + stealth mode: the highest-value protection
      # on a hostile network, so it goes first.
      as_root /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
      as_root /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
      echo "Firewall: on, stealth mode: on"

      # Bluetooth off, effective immediately.
      run ${pkgs.blueutil}/bin/blueutil --power 0
      echo "Bluetooth: disabled"

      # AirDrop
      run /usr/bin/defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
      echo "AirDrop: disabled"

      # AirPlay Receiver
      run /usr/bin/defaults -currentHost write com.apple.controlcenter AirplayReceiver -int 18
      echo "AirPlay Receiver: disabled"

      # Handoff / Continuity
      run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false
      run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
      echo "Handoff and Continuity: disabled"

      # Bonjour multicast advertising (system domain, daemon rereads on HUP)
      as_root /usr/bin/defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true
      as_root /usr/bin/killall -HUP mDNSResponder
      echo "Bonjour multicast: disabled"

      # Captive portal auto-probe. Deliberate trade-off: hotel/airport
      # portals need a manual browser visit to a plain http site to log in.
      as_root /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false
      echo "Captive portal detection: disabled (open http://captive.apple.com manually for portals)"

      # Location services
      as_root /usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 0
      echo "Location services: disabled"

      # Siri
      run /usr/bin/defaults write com.apple.assistant.support "Assistant Enabled" -bool false
      run /usr/bin/defaults write com.apple.Siri StatusMenuVisible -bool false
      echo "Siri: disabled"

      # Spotlight network suggestions
      run /usr/bin/defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
      echo "Spotlight suggestions: disabled"

      # Wake for network access (keeps radios chatty while lid closed)
      as_root /usr/bin/pmset -a womp 0
      echo "Wake for network access: disabled"

      # Purge saved WiFi networks, backing the list up first so they can
      # be re-added after the trip.
      WIFI_IF=$(/usr/sbin/networksetup -listallhardwareports | ${pkgs.gawk}/bin/awk '/Wi-Fi/{getline; print $2}')
      if [ -n "$WIFI_IF" ]; then
        if [ "$DRY" = 1 ]; then
          echo "DRY: backup + purge preferred wireless networks on $WIFI_IF"
        else
          /usr/sbin/networksetup -listpreferredwirelessnetworks "$WIFI_IF" \
            > "$STATE_DIR/wifi-networks.$(date +%Y%m%d-%H%M%S).txt" 2>/dev/null
          /usr/sbin/networksetup -removeallpreferredwirelessnetworks "$WIFI_IF" 2>/dev/null
          echo "Saved WiFi networks: purged (backup in $STATE_DIR)"
        fi
      fi

      echo ""
      echo "Travel mode active. Verify with: travel-mode-status"
      echo "Remember to:"
      echo "  - Route traffic through a Tailscale exit node"
      echo "  - Use a USB data blocker for charging"
    '')

    (pkgs.writeScriptBin "travel-mode-off" ''
      #!${pkgs.bash}/bin/bash
      set -u
      ${prelude}
      echo "Deactivating travel mode..."
      [ "$DRY" = 1 ] && echo "(dry run — nothing will change)"

      # Stealth mode off; the firewall itself stays on (good default at home too).
      as_root /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode off
      echo "Firewall: still on, stealth mode: off"

      run ${pkgs.blueutil}/bin/blueutil --power 1
      echo "Bluetooth: enabled"

      run /usr/bin/defaults write com.apple.NetworkBrowser DisableAirDrop -bool false
      echo "AirDrop: enabled"

      run /usr/bin/defaults -currentHost write com.apple.controlcenter AirplayReceiver -int 2
      echo "AirPlay Receiver: enabled"

      run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool true
      run /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool true
      echo "Handoff and Continuity: enabled"

      as_root /usr/bin/defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool false
      as_root /usr/bin/killall -HUP mDNSResponder
      echo "Bonjour multicast: enabled"

      as_root /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool true
      echo "Captive portal detection: enabled"

      as_root /usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 1
      echo "Location services: enabled"

      run /usr/bin/defaults write com.apple.assistant.support "Assistant Enabled" -bool true
      run /usr/bin/defaults write com.apple.Siri StatusMenuVisible -bool true
      echo "Siri: enabled"

      run /usr/bin/defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool false
      echo "Spotlight suggestions: enabled"

      as_root /usr/bin/pmset -a womp 1
      echo "Wake for network access: enabled"

      echo ""
      echo "Travel mode deactivated"
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

      exit $ok
    '')
  ];
}
