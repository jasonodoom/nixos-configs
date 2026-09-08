#!/usr/bin/env bash
# Local gate for each host flake whose files were staged: eval check for
# all, plus a sandbox-forced darwin build when an apple .nix is staged.
set -euo pipefail

staged=$(git diff --cached --name-only)

hosts=()
for host in framework-desktop lenovo-thinkcentre-m710q apple-macbook-air-m2; do
  if grep -qE "^($host/|modules/)" <<< "$staged"; then
    hosts+=("$host")
  fi
done

if [ ${#hosts[@]} -eq 0 ]; then
  exit 0
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "pre-commit: nix not found on PATH, skipping flake check" >&2
  exit 0
fi

fail=0
for host in "${hosts[@]}"; do
  echo "==> nix flake check $host"
  if ! (cd "$host" && nix flake check --no-build --accept-flake-config 2>&1); then
    fail=1
  fi
done

if grep -qE "^(apple-macbook-air-m2/|modules/).*\.nix$" <<< "$staged"; then
  echo "==> sandboxed build apple-macbook-air-m2 (purity gate)"
  if ! (cd apple-macbook-air-m2 && nix build --no-link --accept-flake-config \
      --option sandbox true .#darwinConfigurations.theophany.system 2>&1); then
    echo "pre-commit: darwin system fails to build under the sandbox." >&2
    echo "pre-commit: a derivation reaches outside the store. Build it from" >&2
    echo "pre-commit: store tools, or use a system tool at runtime not build time." >&2
    fail=1
  fi
fi

exit $fail
