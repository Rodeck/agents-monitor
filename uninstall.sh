#!/bin/bash
# Claude Monitor — uninstall
set -euo pipefail

APP_NAME="ClaudeMonitor"
APP_INSTALL_PATH="/Applications/${APP_NAME}.app"
HOOK_PATH="$HOME/.claude/hooks/claude-monitor-hook.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}!${NC} $1"; }

echo ""
echo -e "${BOLD}Claude Monitor Uninstall${NC}"
echo ""

# Stop running instance
if pgrep -x "$APP_NAME" &>/dev/null; then
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    info "Stopped Claude Monitor"
fi

# Remove app
if [ -d "$APP_INSTALL_PATH" ]; then
    rm -rf "$APP_INSTALL_PATH"
    info "Removed $APP_INSTALL_PATH"
else
    warn "App not found at $APP_INSTALL_PATH"
fi

# Remove hook script
if [ -f "$HOOK_PATH" ]; then
    rm "$HOOK_PATH"
    info "Removed $HOOK_PATH"
else
    warn "Hook script not found at $HOOK_PATH"
fi

# Remove hooks from settings.json
if [ -f "$SETTINGS_FILE" ] && grep -q "claude-monitor-hook.sh" "$SETTINGS_FILE"; then
    if command -v jq &>/dev/null; then
        # Remove any hook entries that reference our script
        jq '
            if .hooks then
                .hooks |= (
                    with_entries(
                        .value |= map(select(
                            .hooks | all(.command | test("claude-monitor-hook") | not)
                        ))
                    ) | with_entries(select(.value | length > 0))
                ) |
                if .hooks == {} then del(.hooks) else . end
            else . end
        ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        info "Removed hooks from $SETTINGS_FILE"
    else
        warn "jq not available — please manually remove claude-monitor-hook entries from $SETTINGS_FILE"
    fi
else
    warn "No Claude Monitor hooks found in settings"
fi

# Clean up socket
rm -f /tmp/claude-monitor.sock 2>/dev/null

echo ""
echo -e "${GREEN}${BOLD}Uninstall complete.${NC}"
echo ""
