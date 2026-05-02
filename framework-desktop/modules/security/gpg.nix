# GPG and smart card configuration for perdurabo
{ config, pkgs, lib, ... }:

let
  jasonodoomKey = builtins.fetchurl {
    url = "https://github.com/jasonodoom.gpg";
    sha256 = "sha256-4hboVMmEdIcxfWpe4mizxp2A4ZZuRtB0MnQuyvnJt9U=";
  };
  webFlowKey = builtins.fetchurl {
    url = "https://github.com/web-flow.gpg";
    sha256 = "sha256-bor2h/YM8/QDFRyPsbJuleb55CTKYMyPN4e9RGaj74Q=";
  };

  # Expected fingerprints. Imported keys are checked against these and the
  # service fails if either upstream rotated without us updating the pin.
  jasonodoomFingerprint = "F3DD4A7B465A4EB1823E2EE268CCAF80768A91A5";
  webFlowFingerprints = [
    "5DE3E0509C47EA3CF04A42D34AEE18F83AFDEB23"
    "968479A1AFF927E37D1A566BB5690EEEBB952194"
  ];
in
{
  services.pcscd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  # Imports keys used by verify-upgrade-commits. Trust assignment is limited
  # to jasonodoom; verify-upgrade-commits matches signing fingerprints
  # directly via VALIDSIG and does not rely on web-flow being trusted.
  systemd.services.import-gpg-key = {
    description = "Import GPG public keys for commit verification";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "jason";
    };
    path = [ pkgs.gnupg pkgs.gawk ];
    script = ''
      set -euo pipefail

      EXPECTED_JASON="${jasonodoomFingerprint}"
      EXPECTED_WEBFLOW="${lib.concatStringsSep " " webFlowFingerprints}"

      gpg --import "${jasonodoomKey}"
      JASON_FPR=$(gpg --list-keys --with-colons --fingerprint "$EXPECTED_JASON" 2>/dev/null \
        | awk -F: '/^fpr/ {print $10; exit}')
      if [ "$JASON_FPR" != "$EXPECTED_JASON" ]; then
        echo "ERROR: jasonodoom key fingerprint mismatch (got '$JASON_FPR', expected '$EXPECTED_JASON')" >&2
        exit 1
      fi
      echo "$JASON_FPR:6:" | gpg --import-ownertrust

      gpg --import "${webFlowKey}"
      for fpr in $EXPECTED_WEBFLOW; do
        if ! gpg --list-keys --with-colons --fingerprint "$fpr" >/dev/null 2>&1; then
          echo "ERROR: expected web-flow fingerprint $fpr not present after import" >&2
          exit 1
        fi
      done

      echo "GPG public keys imported and verified"
    '';
  };

  systemd.timers.import-gpg-key = {
    description = "Refresh GPG keys";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}
