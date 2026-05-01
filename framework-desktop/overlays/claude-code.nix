# Claude Code overlay - native binary from Anthropic
# Updated automatically by .github/workflows/update-claude-code.yml
let
  version = "2.1.126";
  platform = "linux-x64";
  hash = "sha256-/OlpaNJ1Fh/2WkwZ/GQ078aXPZ9tNdw5kqK6BVPKwY4=";
in
final: prev: {
  claude-code = final.stdenv.mkDerivation {
    pname = "claude-code";
    inherit version;
    src = final.fetchurl {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/${platform}/claude";
      inherit hash;
    };
    dontUnpack = true;
    nativeBuildInputs = [ final.autoPatchelfHook ];
    buildInputs = [ final.stdenv.cc.cc.lib ];
    installPhase = ''
      install -Dm755 $src $out/bin/claude
    '';
  };
}
