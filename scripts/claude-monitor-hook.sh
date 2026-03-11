#!/bin/bash
# Claude Monitor hook script for Claude Code
# Sends session state events to the Claude Monitor app via Unix socket.
#
# Usage: claude-monitor-hook.sh <state>
#   state: running | attention | idle
#
# Reads Claude Code hook JSON from stdin (contains session_id, cwd, etc.)
# Sends compact JSON to /tmp/claude-monitor.sock
# Exits 0 silently on any failure (must never block Claude Code).

set -e

SOCKET="/tmp/claude-monitor.sock"
STATE="${1:-running}"
INPUT=$(cat)

# Extract session_id and cwd from hook JSON input
if command -v jq &>/dev/null; then
    SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
    CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
else
    # Pure-bash fallback: extract values from JSON using grep/sed
    SID=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)"/\1/' 2>/dev/null)
    CWD=$(echo "$INPUT" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)"/\1/' 2>/dev/null)
fi

# Bail if we couldn't extract session_id
[ -z "$SID" ] && exit 0

TS=$(date +%s)
MSG="{\"sid\":\"${SID}\",\"state\":\"${STATE}\",\"cwd\":\"${CWD}\",\"ts\":${TS}}"

# Send to socket; fail silently if app not running
echo "$MSG" | nc -U "$SOCKET" 2>/dev/null || true

exit 0
