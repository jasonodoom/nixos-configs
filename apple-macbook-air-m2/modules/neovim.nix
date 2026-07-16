# Thin wrapper: real config lives in the shared module.
{ ... }:
{
  imports = [ ../../modules/shared/neovim.nix ];
}
