# Claude Code overlay - pinned to 2.1.85
let
  version = "2.1.85";
  hash = "sha256-kCNzGoLCu/TwSTs3CYx1aes+6WRbVGTpLsHEyGTVGDc=";
  npmDepsHash = "sha256-pMqES3AHX1/b8A3SghO63vE8ej2i6iB+YjzAUJ2iitM=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.85-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.85-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
