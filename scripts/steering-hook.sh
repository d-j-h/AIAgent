#!/usr/bin/env bash
#
# steering-hook.sh
# Antigravity PreInvocation hook that:
# 1. Triggers background sync if > 10 minutes since last check
# 2. Injects an ephemeral steering prompt into the AI agent's context
#

set -euo pipefail

SYNC_SCRIPT="${HOME}/git/AIAgent/scripts/sync-and-update.sh"
STAMP_FILE="/tmp/.last_steering_sync"
NOW=$(date +%s)

# Read stdin to consume payload
cat > /dev/null

# Non-blocking sync check every 10 minutes (600 seconds)
if [ ! -f "$STAMP_FILE" ] || [ $(( NOW - $(cat "$STAMP_FILE" 2>/dev/null || echo 0) )) -gt 600 ]; then
  echo "$NOW" > "$STAMP_FILE"
  if [ -x "$SYNC_SCRIPT" ]; then
    "$SYNC_SCRIPT" >/dev/null 2>&1 &
  fi
fi

# Output PreInvocation response
cat << 'JSON'
{
  "injectSteps": [
    {
      "ephemeralMessage": "[Steering Directive] Ensure all actions comply with AIAgent steering rules: verify code with tests/lints before completion, produce minimal focused diffs, prevent credential leaks, and follow project standards."
    }
  ]
}
JSON
