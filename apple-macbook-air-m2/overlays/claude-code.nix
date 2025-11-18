 # Claude Code overlay - pinned to 2.0.5
  let
    version = "2.0.5";
    hash = "sha256-vT+Csqi3vtAbQam6p2qzefBycFDkUO+k5EdHHcCPT2k=";
    npmDepsHash = "sha256-oI1a8QdkHRPGeSQjGDFAX2lsojbJYyuUTDXw1wohG3U=";
  in
  final: prev: {
    claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
      inherit version;
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.0.5-package-lock.json} package-lock.json
      '';
      npmDeps = prev.fetchNpmDeps {
        src = prev.fetchurl {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          inherit hash;
        };
        postPatch = ''
          cp ${./claude-code-2.0.5-package-lock.json} package-lock.json
        '';
        hash = npmDepsHash;
      };
    });
  }
