{ inputs, ... }:

final: prev: {
  inherit (import ./claude-code.nix final prev) claude-code;

  # LLM agents from numtide/llm-agents.nix
  llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};

  # wrangler from the pin until 4.93.0 builds on macos.
  wrangler = (import inputs.nixpkgs-wrangler-pin {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  }).wrangler;
}
