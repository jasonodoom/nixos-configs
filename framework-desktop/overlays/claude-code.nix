# Claude Code overlay - pinned to 2.1.25
let
  version = "2.1.25";
  hash = "sha256-5DPy4JMc16bvb1lsRzSlf01OPa0FMvLXf/KH+3Zy0wQ=";
  npmDepsHash = "sha256-QH117ZS1pJgqTorGgn/YY/oU0X2/b033dOqRcU+oR5M=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.25-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.25-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
