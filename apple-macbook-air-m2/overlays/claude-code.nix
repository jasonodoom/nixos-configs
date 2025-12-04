# Claude Code overlay
  let
    version = "2.0.58";
    hash = "sha256-TkO9ZEte2gLFsS0eQAZK2uZsJUvfgL6TV+VFnD6YGEg=";
    npmDepsHash = "sha256-XOIuOQUJ0HB86pwuUnrv0B121lO9em9XG1DAK0/L4js=";
  in
  final: prev: {
    claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
      inherit version;
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.0.58-package-lock.json} package-lock.json
      '';
      npmDeps = prev.fetchNpmDeps {
        src = prev.fetchurl {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          inherit hash;
        };
        postPatch = ''
          cp ${./claude-code-2.0.58-package-lock.json} package-lock.json
        '';
        hash = npmDepsHash;
      };
    });
  }
