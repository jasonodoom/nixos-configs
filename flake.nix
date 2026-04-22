{
  description = "nixos-configs dev shell (pre-commit, git, tooling used by .envrc)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "nixos-configs-dev";
          packages = with pkgs; [
            # bashInteractive must come first so `bash` in this devShell
            # resolves to a shell with readline/bind/progcomp, not the
            # stripped stdenv bash that normally ends up in devShell PATH.
            bashInteractive
            git
            pre-commit
            gitleaks
            nixfmt
            shellcheck
            shfmt
          ];
          shellHook = ''
            if [ -d .git ] && [ -f .pre-commit-config.yaml ] && [ ! -f .git/hooks/pre-commit ]; then
              echo "installing pre-commit git hooks..."
              pre-commit install --install-hooks >/dev/null 2>&1 || true
            fi
          '';
        };
      });
}
