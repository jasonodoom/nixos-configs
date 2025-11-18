{ config, pkgs, lib, ... }:

{
  # Dock behavior and appearance settings
  # Note: Not managing dock apps (local.dock) to preserve manually pinned apps
  system.defaults.dock = {
    autohide = false;
    orientation = "left";
    show-recents = false;
    mru-spaces = false;
    tilesize = 48;
    largesize = 64;
    magnification = true;
    mineffect = "genie";
    minimize-to-application = true;
    show-process-indicators = true;
    showhidden = true;
    static-only = false;
  };
}
