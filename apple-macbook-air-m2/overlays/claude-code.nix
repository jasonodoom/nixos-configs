# Claude Code overlay - pinned to 2.1.80
let
  version = "2.1.80";
  hash = "sha256-AoufUosfpysMmHa+/O8pBanTt8cLlsUlw6eO0vXQLFA=";
  npmDepsHash = "sha256-PxQh0bXPRotAzPxOuNZHrtxmHw89e0rlnRN/zdMhIEA=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.80-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.80-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
