# Claude Code overlay - pinned to 2.1.17
let
  version = "2.1.17";
  hash = "sha256-Tug122dgT/TpTeEpBQx38O948CxLf59VOfsDF+Dde6w=";
  npmDepsHash = "sha256-aUqPXF5L78wZ34pNRvpEJi6l2wl15Og1yCEvVoeV0tE=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.17-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.17-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
