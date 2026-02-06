# Claude Code overlay - pinned to 2.1.34
let
  version = "2.1.34";
  hash = "sha256-9poksTheZl3zwxmGwTNwAmUmTooZCY5huFqe73RYh1A=";
  npmDepsHash = "sha256-n762einDxLUUXWMsfdPVhA/kn0ywlJgFQ2ZGoEk3E68=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.34-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.34-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
