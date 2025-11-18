{ config, pkgs, lib, ... }:

{
  # Firefox is installed via Homebrew (see homebrew.nix)
  # This module manages Firefox preferences via user.js
  # Note: Firefox from nixpkgs is broken on macOS, use Homebrew cask instead :(

  system.activationScripts.firefox-config.text = ''
    USER_HOME="/Users/${config.system.primaryUser}"
    FIREFOX_PROFILE_DIR="$USER_HOME/Library/Application Support/Firefox/Profiles"

    # Wait for Firefox to create profile on first run
    if [ -d "$FIREFOX_PROFILE_DIR" ]; then
      # Find the default-release profile
      PROFILE=$(find "$FIREFOX_PROFILE_DIR" -maxdepth 1 -name "*.default-release" -type d | head -1)

      if [ -n "$PROFILE" ]; then
        echo "Configuring Firefox profile: $PROFILE"

        # Create user.js for custom preferences
        # These will override prefs.js on each Firefox startup
        cat > "$PROFILE/user.js" << 'EOF'
// Privacy and Security Settings
// DNS over HTTPS (DoH) with Cloudflare
user_pref("doh-rollout.mode", 2);
user_pref("doh-rollout.uri", "https://mozilla.cloudflare-dns.com/dns-query");
user_pref("network.trr.mode", 2);

// Disable DNS prefetching (privacy)
user_pref("network.dns.disablePrefetch", true);

// Disable network prefetching
user_pref("network.prefetch-next", false);

// Disable link prefetching
user_pref("network.http.speculative-parallel-limit", 0);

// Disable WebRTC IP leak
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);

// Enhanced Tracking Protection - Strict
user_pref("browser.contentblocking.category", "strict");

// Disable telemetry
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);

// Restore previous session
user_pref("browser.startup.page", 3);

// Disable geolocation
user_pref("geo.enabled", false);

// Disable Firefox Accounts push service
user_pref("identity.fxaccounts.enabled", false);

// Disable Firefox Sync
user_pref("services.sync.engine.prefs", false);

// Disable form autofill
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);

// Always ask where to save files
user_pref("browser.download.useDownloadDir", false);
EOF

        chmod 644 "$PROFILE/user.js"
        chown ${config.system.primaryUser}:staff "$PROFILE/user.js"
        echo "Firefox configuration applied to user.js"
      else
        echo "Firefox profile not found - will be created on first Firefox launch"
      fi
    else
      echo "Firefox not yet initialized - user.js will be created on first activation after Firefox setup"
    fi
  '';
}
