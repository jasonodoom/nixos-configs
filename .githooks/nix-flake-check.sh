#!/usr/bin/env bash
# Fast local gate: run `nix flake check --no-build` for each host flake
# whose files were staged. Catches module-eval errors (wrong option names,
# type mismatches, failed assertions) before they reach CI.
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

exit $fail
