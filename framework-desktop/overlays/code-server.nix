# Code-server overlay
let
  version = "4.105.1";
  hash = "sha256-75k2Vugv+46oVG/Ppxdn7uWryDR4gzj4uSVFNY6YAQM=";
in
final: prev: {
  code-server =
    if (prev ? code-server) then
      prev.code-server.overrideAttrs (oldAttrs: {
        inherit version;
        src = prev.fetchFromGitHub {
          owner = "coder";
          repo = "code-server";
          rev = "v${version}";
          fetchSubmodules = true;
          inherit hash;
        };
      })
    else
      prev.writeShellScriptBin "code-server" ''
        echo "code-server not available"
        exit 1
      '';
}
