# Claude Code overlay - pinned to 2.1.91
let
  version = "2.1.91";
  hash = "sha256-T7Ta53HW+tHnRwN0EUj17i0kg39KBOqycEF0b3pbPis=";
  npmDepsHash = "sha256-0ppKP+XMgTzVVZtL7GDsOjgvSPUDrUa7SoG048RLaNg=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.91-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.91-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
