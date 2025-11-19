{ inputs, ... }:

final: prev: {
  inherit (import ./claude-code.nix final prev) claude-code;
}
