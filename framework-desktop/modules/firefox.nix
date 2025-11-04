# Firefox configuration with extensions
{ config, pkgs, lib, ... }:

{
  # Firefox with extensions
  environment.systemPackages = with pkgs; [
    (firefox.override {
      extraPolicies = {
        DefaultSettings = {
          "ui.systemUsesDarkTheme" = 1;
        };
      };
    })
  ];

  # Firefox extensions to install manually (I do not want to use Home Manager):
  # - Dark Reader (addon@darkreader.org)
  # - MetaMask (webextension@metamask.io)
  # - Momentum (momentum@momentumdash.com)
  # - Privacy Badger (jid1-MnnxcxisBPnSXQ@jetpack)


}