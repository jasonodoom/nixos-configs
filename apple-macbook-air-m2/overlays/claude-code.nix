# Claude Code overlay - pinned to 2.1.74
let
  version = "2.1.74";
  hash = "sha256-3OM+J+r4knZZjp2uUJnhJsJYDOpR62Rx4cN0eICdGBg=";
  npmDepsHash = "sha256-FQEQQK8UIvPw8WMYGW+X7TPAWi+SVJEhUV0MqO2gQz0=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.74-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.74-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
