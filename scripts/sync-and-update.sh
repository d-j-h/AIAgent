#!/usr/bin/env bash
#
# sync-and-update.sh
# Regularly pulls the latest AIAgent repository from GitHub,
# and updates Antigravity & Kiro steering configurations when changes occur.
#

set -euo pipefail

REPO_DIR="${HOME}/git/AIAgent"
LOG_FILE="${HOME}/.gemini/antigravity/log/steering_sync.log"
CONFIG_DIR="${HOME}/.gemini/config"
RULES_DIR="${CONFIG_DIR}/rules"
GLOBAL_KIRO="${HOME}/.kiro/steering"
SKILLS_DIR="${HOME}/.gemini/skills/ai-agent-steering"

mkdir -p "$(dirname "$LOG_FILE")" "$RULES_DIR" "$GLOBAL_KIRO" "$SKILLS_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

cd "$REPO_DIR"

# 1. Check for remote updates safely using SSH with timeout
export GIT_SSH_COMMAND="ssh -o ConnectTimeout=5 -o BatchMode=yes"

if ! git fetch origin main --quiet 2>/dev/null; then
  # If offline or remote unreachable, exit cleanly without breaking
  exit 0
fi

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/main)

UPDATED=false

if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
  log "Update detected in AIAgent ($LOCAL_HASH -> $REMOTE_HASH). Pulling changes..."
  git pull --ff-only origin main --quiet
  UPDATED=true
  log "Successfully updated AIAgent to $REMOTE_HASH."
fi

# 2. Update / Re-link Antigravity Global Rules & Steering Files
update_integrations() {
  # Symlink all core steering files into ~/.gemini/config/rules and ~/.kiro/steering
  for f in "${REPO_DIR}/steering"/*.md; do
    [ -e "$f" ] || continue
    fname="$(basename "$f")"
    ln -sfn "$f" "${RULES_DIR}/${fname}"
    ln -sfn "$f" "${GLOBAL_KIRO}/${fname}"
  done

  # Link global AGENTS.md and GEMINI.md in ~/.gemini/config
  ln -sfn "${REPO_DIR}/templates/general/AGENTS.md" "${CONFIG_DIR}/AGENTS.md"
  ln -sfn "${REPO_DIR}/templates/general/GEMINI.md" "${CONFIG_DIR}/GEMINI.md"

  # Link the AI Agent Steering Skill into Antigravity's global skills directory
  ln -sfn "${REPO_DIR}/skills/ai-agent-steering/SKILL.md" "${SKILLS_DIR}/SKILL.md"
}

# Always ensure integrations are correctly linked
update_integrations

if [ "$UPDATED" = true ]; then
  log "Antigravity and Kiro steering configurations reloaded."
fi
