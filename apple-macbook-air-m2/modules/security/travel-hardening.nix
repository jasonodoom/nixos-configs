# Travel hardening for hostile network environments
# Set enabled to true and rebuild to auto-apply on activation
# Scripts travel-mode-on and travel-mode-off are always available regardless of toggle
{ config, pkgs, lib, ... }:

let
  enabled = false;
in
{
  system.activationScripts.travel-hardening = lib.mkIf enabled {
    text = ''
      echo "Applying travel hardening..."
      /run/current-system/sw/bin/travel-mode-on
    '';
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "travel-mode-on" ''
      #!${pkgs.bash}/bin/bash
      echo "Activating travel mode..."

      # FileVault check
      if ! fdesetup status | grep -q "FileVault is On"; then
        echo "WARNING: FileVault is NOT enabled — your disk is not encrypted"
      else
        echo "FileVault: on"
      fi

      # Disable Bluetooth
      /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
      echo "Bluetooth: disabled"

      # Disable AirDrop
      /usr/bin/defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
      echo "AirDrop: disabled"

      # Disable AirPlay Receiver
      /usr/bin/defaults -currentHost write com.apple.controlcenter AirplayReceiver -int 18
      echo "AirPlay Receiver: disabled"

      # Disable Handoff and Continuity
      /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false
      /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false
      echo "Handoff and Continuity: disabled"

      # Disable Bonjour multicast advertising
      /usr/bin/defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true
      echo "Bonjour multicast: disabled"

      # Disable captive portal detection
      /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false
      echo "Captive portal detection: disabled"

      # Disable location services
      sudo /usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 0
      echo "Location services: disabled"

      # Disable Siri
      /usr/bin/defaults write com.apple.assistant.support "Assistant Enabled" -bool false
      /usr/bin/defaults write com.apple.Siri StatusMenuVisible -bool false
      echo "Siri: disabled"

      # Disable Spotlight network suggestions
      /usr/bin/defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
      echo "Spotlight suggestions: disabled"

      # Purge saved WiFi networks
      WIFI_IF=$(/usr/sbin/networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
      if [ -n "$WIFI_IF" ]; then
        /usr/sbin/networksetup -removeallpreferredwirelessnetworks "$WIFI_IF" 2>/dev/null
        echo "Saved WiFi networks: purged"
      fi

      echo ""
      echo "Travel mode active. Remember to:"
      echo "  - Route traffic through Tailscale exit node"
      echo "  - Use a USB data blocker for charging"
    '')

    (pkgs.writeScriptBin "travel-mode-off" ''
      #!${pkgs.bash}/bin/bash
      echo "Deactivating travel mode..."

      # Enable Bluetooth
      /usr/bin/defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 1
      echo "Bluetooth: enabled"

      # Enable AirDrop
      /usr/bin/defaults write com.apple.NetworkBrowser DisableAirDrop -bool false
      echo "AirDrop: enabled"

      # Enable AirPlay Receiver
      /usr/bin/defaults -currentHost write com.apple.controlcenter AirplayReceiver -int 2
      echo "AirPlay Receiver: enabled"

      # Enable Handoff and Continuity
      /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool true
      /usr/bin/defaults -currentHost write com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool true
      echo "Handoff and Continuity: enabled"

      # Enable Bonjour multicast
      /usr/bin/defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool false
      echo "Bonjour multicast: enabled"

      # Enable captive portal detection
      /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool true
      echo "Captive portal detection: enabled"

      # Enable location services
      sudo /usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 1
      echo "Location services: enabled"

      # Enable Siri
      /usr/bin/defaults write com.apple.assistant.support "Assistant Enabled" -bool true
      /usr/bin/defaults write com.apple.Siri StatusMenuVisible -bool true
      echo "Siri: enabled"

      # Enable Spotlight suggestions
      /usr/bin/defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool false
      echo "Spotlight suggestions: enabled"

      echo ""
      echo "Travel mode deactivated"
      echo "Note: saved WiFi networks were purged — re-add your networks manually"
    '')
  ];
}
