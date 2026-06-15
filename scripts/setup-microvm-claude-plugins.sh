#!/usr/bin/env bash
# setup-microvm-claude-plugins.sh — provision the anthropic plugin
# marketplace inside each ai-microvm so claude/codex/gemini agents
# running there have the same plugin set the operator has locally.
#
# Why not nixos-managed: the marketplace is a fast-moving git repo
# anthropic updates frequently. Baking it as a fetchFromGitHub
# derivation would force a system rebuild + microvm restart on
# every plugin update. Cloning into the agent's home (with a
# `--depth 1` fetch and `git pull` on subsequent runs) keeps
# updates cheap and operator-paced.
#
# Run on each VM after a fresh microvm provision:
#   ssh agent@ai-claude  bash -s < scripts/setup-microvm-claude-plugins.sh
#   ssh agent@ai-codex   bash -s < scripts/setup-microvm-claude-plugins.sh
#   ssh agent@ai-gemini  bash -s < scripts/setup-microvm-claude-plugins.sh
#
# Idempotent: re-running on an already-provisioned VM just `git
# pull`s the marketplace.

set -euo pipefail

PLUGINS_DIR="${HOME}/.claude/plugins"
MARKETPLACES_DIR="${PLUGINS_DIR}/marketplaces"
OFFICIAL_REPO="https://github.com/anthropics/claude-plugins-official.git"
OFFICIAL_LOCAL="${MARKETPLACES_DIR}/claude-plugins-official"

log() { printf '[claude-plugins] %s\n' "$*"; }

mkdir -p "${MARKETPLACES_DIR}"

if [ -d "${OFFICIAL_LOCAL}/.git" ]; then
  log "marketplace already cloned, pulling latest"
  git -C "${OFFICIAL_LOCAL}" pull --ff-only --quiet
elif [ -d "${OFFICIAL_LOCAL}" ]; then
  # Pre-existing non-git checkout (e.g. installed via a different
  # bootstrap on a previous VM image). Leave the tree alone; just
  # update the registration JSON. Operator can manually convert to
  # a git checkout if they want self-update via `git pull`.
  log "marketplace exists (non-git); leaving tree alone"
else
  log "cloning anthropic plugin marketplace"
  git clone --depth 1 --quiet "${OFFICIAL_REPO}" "${OFFICIAL_LOCAL}"
fi

# Register the marketplace pointer so `claude /plugin marketplace
# list` sees it. The schema mirrors what claude writes when the
# operator runs `/plugin marketplace add` interactively.
KNOWN="${PLUGINS_DIR}/known_marketplaces.json"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "${KNOWN}.tmp" <<EOF
{
  "claude-plugins-official": {
    "source": {
      "source": "github",
      "repo": "anthropics/claude-plugins-official"
    },
    "installLocation": "${OFFICIAL_LOCAL}",
    "lastUpdated": "${NOW}"
  }
}
EOF
mv "${KNOWN}.tmp" "${KNOWN}"
log "registered marketplace pointer at ${KNOWN}"

# Initialize an empty blocklist if one isn't present. Claude code
# expects the file to exist; absence triggers a noisy "create
# blocklist?" prompt at every plugin operation.
BLOCKLIST="${PLUGINS_DIR}/blocklist.json"
if [ ! -f "${BLOCKLIST}" ]; then
  cat > "${BLOCKLIST}" <<EOF
{
  "fetchedAt": "${NOW}",
  "plugins": []
}
EOF
  log "wrote empty blocklist at ${BLOCKLIST}"
fi

EXT="${OFFICIAL_LOCAL}/external_plugins"
if [ -d "${EXT}" ]; then
  COUNT="$(find "${EXT}" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')"
  log "available external plugins: ${COUNT}"
fi

log "done. Run \`claude /plugin\` inside the microvm to list & install."
