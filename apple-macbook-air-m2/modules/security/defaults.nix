# System security defaults
{ config, pkgs, lib, ... }:

{
  system.defaults = {
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    loginwindow = {
      GuestEnabled = false;
      DisableConsoleAccess = true;
    };
  };

  networking.applicationFirewall = {
    enable = true;
    blockAllIncoming = true;
    enableStealthMode = true;
    allowSignedApp = false;
    allowSigned = false;
  };

  system.activationScripts.check-filevault.text = ''
    if ! fdesetup status | grep -q "FileVault is On"; then
      echo "WARNING: FileVault is NOT enabled"
    fi
  '';

  system.activationScripts.disable-remote-login.text = ''
    systemsetup -setremotelogin off 2>/dev/null || true
  '';
}
