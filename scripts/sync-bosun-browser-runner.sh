#!/usr/bin/env bash
# Copy the bosun-browser-runner source from ~/code/bosun/runners/browser
# into the perdurabo runner state directory and `npm install` so the
# microvm can boot. Re-run after editing the runner.
#
# Designed to run ON perdurabo (or via ssh perdurabo bash -s).
set -euo pipefail

STATE=/home/jason/.local/state/bosun/browser-runner
SRC=${BOSUN_RUNNER_SRC:-/home/jason/code/bosun/runners/browser}

if [[ ! -d "$SRC" ]]; then
  echo "error: $SRC does not exist." >&2
  echo "       set BOSUN_RUNNER_SRC=/path/to/bosun/runners/browser if the repo is elsewhere." >&2
  exit 1
fi

mkdir -p "$STATE"
rsync -a --delete --exclude=node_modules --exclude=.pw "$SRC/" "$STATE/"

cd "$STATE"
if [[ -d node_modules ]]; then
  echo "+ npm ci"
  npm ci --omit=dev
else
  echo "+ npm install (first time)"
  npm install --omit=dev
fi

echo
echo "Runner staged at $STATE."
echo "Restart the VM to pick up changes:"
echo "  systemctl restart microvm@bosun-browser"
