# Claude Code overlay - pinned to 2.1.70
let
  version = "2.1.70";
  hash = "sha256-YGPF83dBBfYlAZftP9wLpPZPx2y8Q9jSmX12gvB5Z9I=";
  npmDepsHash = "sha256-k+UORB4anWeBQIr+XbkKjsw792e/viz2Ous8rXKuYJI=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.70-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.70-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
