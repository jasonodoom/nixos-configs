# Claude Code overlay - pinned to 2.1.100
let
  version = "2.1.100";
  hash = "sha256-Dkip2mnbcvks8SbZVBqXajaRi1SQEemN2IDiHxlaqbA=";
  npmDepsHash = "sha256-Vvi6ETFLSJSUZgcUxss/WQapxR/8EfSVsKlTRP+iyss=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.100-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.100-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
