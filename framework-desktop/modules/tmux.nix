# Thin wrapper: the real config lives in the shared module so
# framework-desktop and lenovo stay in lockstep.
{ ... }:
{
  imports = [ ../../modules/shared/tmux.nix ];
}
