# Claude Code overlay - native binary from Anthropic
# Updated automatically by .github/workflows/update-claude-code.yml
let
  version = "2.1.218";
  platform = "linux-x64";
  hash = "sha256-4SBxdRqTNrivEBLBAzWP8ErBj5qv9Kc4z/e6XN+vY/I=";
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
    # Ship the binary byte-for-byte. claude-code is a Bun single-file
    # executable with the JS payload appended after the ELF; any post-build
    # touching (autoPatchelfHook, strip, the default fixup patchelf pass)
    # shifts the trailer offset and Bun can't find the payload. nix-ld in
    # the guest supplies /lib64/ld-linux-x86-64.so.2 and libstdc++.
    dontStrip = true;
    dontPatchELF = true;
    installPhase = ''
      install -Dm755 $src $out/bin/claude
    '';
  };
}
