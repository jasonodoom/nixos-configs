# Claude Code overlay - pinned to 2.1.62
let
  version = "2.1.62";
  hash = "sha256-TtogpvydBItoSYgQDXu3hBVC1UomQSGFaSubZfklzS4=";
  npmDepsHash = "sha256-b8lv/rduKqgq3lZ5zL3sax9PP3afe4pFpUJHg1K9N5M=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.62-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.62-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
