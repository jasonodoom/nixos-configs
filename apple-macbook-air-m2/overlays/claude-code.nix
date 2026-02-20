# Claude Code overlay - pinned to 2.1.49
let
  version = "2.1.49";
  hash = "sha256-hIJ4s0PcuXMf8DlmSIzZLAGzEkJkLC+DjBDlO2PvnDk=";
  npmDepsHash = "sha256-1xegdmwpBi4ODxfo0jsNE57XuogUPCyjTApodOq3zUA=";
in
final: prev: {
  claude-code = prev.claude-code.overrideAttrs (oldAttrs: {
    inherit version;
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-2.1.49-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      src = prev.fetchurl {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        inherit hash;
      };
      postPatch = ''
        cp ${./claude-code-2.1.49-package-lock.json} package-lock.json
      '';
      hash = npmDepsHash;
    };
  });
}
