# Claude Code overlay
let
  version = "2.0.5";
  hash = "sha256-vT+Csqi3vtAbQam6p2qzefBycFDkUO+k5EdHHcCPT2k=";
  npmDepsHash = "sha256-0x3f8c4xx7hlqffjy2qyzpic55rjj5r8i2svkjjlqdl0kf3si6f3";
in
final: prev: {
  claude-code =
    if (prev ? claude-code) then
      prev.claude-code.overrideAttrs (oldAttrs: {
        inherit version npmDepsHash;
        src = prev.fetchurl {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          inherit hash;
        };
      })
    else
      prev.writeShellScriptBin "claude-code" ''
        echo "claude-code not available"
        exit 1
      '';
}