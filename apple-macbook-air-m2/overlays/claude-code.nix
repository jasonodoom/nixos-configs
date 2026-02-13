# Claude Code overlay - pinned to 2.1.41
let
  version = "2.1.41";
  hash = "sha256-xouJ8RZC8CEYxb6DpMZa9cpTNDo5VHAxPVCDbwGCdpk=";
  npmDepsHash = "sha256-FEJDaJOATUNnCF3Pt2zNX7ZGJOBr+OFmoYFArZuV9Q4=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.41-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.41-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
