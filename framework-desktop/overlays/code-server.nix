# Code-server overlay
let
  version = "4.105.1";
  hash = "sha256-75k2Vugv+46oVG/Ppxdn7uWryDR4gzj4uSVFNY6YAQM=";
in
final: prev: {
  code-server =
    if (prev ? code-server) then
      (prev.code-server.override {
        nodejs = final.nodejs_22;
      }).overrideAttrs (oldAttrs: {
        inherit version;
        src = prev.fetchFromGitHub {
          owner = "coder";
          repo = "code-server";
          rev = "v${version}";
          fetchSubmodules = true;
          inherit hash;
        };
        yarnCache = oldAttrs.yarnCache.overrideAttrs {
          outputHash = "sha256-3xDinhLSZJoz7N7Z/+ttDLh82fwyunOTeSE3ULOZcHA=";
        };
      })
    else
      prev.writeShellScriptBin "code-server" ''
        echo "code-server not available"
        exit 1
      '';
}
