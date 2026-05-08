# Claude Code overlay - native binary from Anthropic
# Updated automatically by .github/workflows/update-claude-code.yml
let
  version = "2.1.133";
  platform = "darwin-arm64";
  hash = "sha256-0480REkRyGxz8yvrgoIQCLJr6In6DQyvcIVYDPVzfhQ=";
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
    installPhase = ''
      install -Dm755 $src $out/bin/claude
    '';
  };
}
