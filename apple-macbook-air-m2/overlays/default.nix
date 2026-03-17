{ inputs, ... }:

final: prev: {
  inherit (import ./claude-code.nix final prev) claude-code;

  # LLM agents from numtide/llm-agents.nix
  llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
}
