#!/bin/bash
# Agents Monitor — one-command setup
# Usage: ./setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="AgentsMonitor"
APP_BUNDLE="$SCRIPT_DIR/build/${APP_NAME}.app"
APP_INSTALL_DIR="/Applications"
APP_INSTALL_PATH="$APP_INSTALL_DIR/${APP_NAME}.app"
HOOK_SRC="$SCRIPT_DIR/scripts/agents-monitor-hook.sh"
HOOK_DST="$HOME/.claude/hooks/agents-monitor-hook.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOKS_TEMPLATE="$SCRIPT_DIR/scripts/agents-monitor-hooks.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
echo -e "${BOLD}Agents Monitor Setup${NC}"
echo "Menu bar app that shows AI agent session status"
echo ""

# ── Prerequisites ──────────────────────────────────────────────────

echo -e "${BOLD}Checking prerequisites...${NC}"

if ! command -v swift &>/dev/null; then
    error "Swift not found. Install Xcode or Xcode Command Line Tools:\n  xcode-select --install"
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
info "Swift found: $SWIFT_VERSION"

if ! command -v jq &>/dev/null; then
    warn "jq not found (optional but recommended). Install with: brew install jq"
else
    info "jq found"
fi

# Check macOS version (need 14.0+)
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
if [ "$MACOS_MAJOR" -lt 14 ]; then
    error "macOS 14.0 (Sonoma) or later required. You have $MACOS_VERSION."
fi
info "macOS $MACOS_VERSION"

echo ""

# ── Build ──────────────────────────────────────────────────────────

echo -e "${BOLD}Building app...${NC}"
cd "$SCRIPT_DIR"
swift build -c release 2>&1 | tail -3

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp ".build/release/${APP_NAME}" "$APP_BUNDLE/Contents/MacOS/${APP_NAME}"
cp "${APP_NAME}/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
codesign --force --sign - "$APP_BUNDLE" 2>/dev/null
info "Built $APP_BUNDLE"

# ── Install app to /Applications ───────────────────────────────────

echo ""
echo -e "${BOLD}Installing app...${NC}"

if [ -d "$APP_INSTALL_PATH" ]; then
    # Kill running instance before overwriting
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5
    rm -rf "$APP_INSTALL_PATH"
fi
cp -R "$APP_BUNDLE" "$APP_INSTALL_PATH"
info "Installed to $APP_INSTALL_PATH"

# ── Install hook script ────────────────────────────────────────────

echo ""
echo -e "${BOLD}Installing hook script...${NC}"

mkdir -p "$(dirname "$HOOK_DST")"
cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
info "Installed hook to $HOOK_DST"

# ── Configure Claude Code settings ─────────────────────────────────

echo ""
echo -e "${BOLD}Configuring Claude Code hooks...${NC}"

mkdir -p "$(dirname "$SETTINGS_FILE")"

merge_hooks() {
    # Merge our hooks into existing settings.json using jq
    local existing="$1"
    local template="$2"
    local template_hooks
    template_hooks=$(jq '.hooks' "$template")

    echo "$existing" | jq --argjson new_hooks "$template_hooks" '
        .hooks = (
            (.hooks // {}) as $existing |
            $new_hooks | to_entries | reduce .[] as $entry (
                $existing;
                .[$entry.key] = ((.[$entry.key] // []) + $entry.value | unique_by(.hooks[0].command))
            )
        )
    '
}

merge_hooks_no_jq() {
    # Without jq: check if hooks already present, if not, do a simple merge
    local settings_content="$1"

    if echo "$settings_content" | grep -q "agents-monitor-hook.sh"; then
        warn "Agents Monitor hooks already present in settings — skipping"
        echo "$settings_content"
        return
    fi

    # If file has existing hooks, warn and provide manual instructions
    if echo "$settings_content" | grep -q '"hooks"'; then
        warn "Existing hooks detected but jq not available for safe merge."
        warn "Please manually merge $HOOKS_TEMPLATE into $SETTINGS_FILE"
        echo "$settings_content"
        return
    fi

    # No existing hooks — safe to add
    # Remove trailing } and append hooks
    local hooks_content
    hooks_content=$(cat "$HOOKS_TEMPLATE")
    # Merge the two JSON objects
    local trimmed
    trimmed=$(echo "$settings_content" | sed '$ s/}$//')
    local hooks_inner
    hooks_inner=$(echo "$hooks_content" | sed '1 s/^{//' | sed '$ s/}$//')

    # Check if existing content has any keys
    if echo "$trimmed" | grep -q '"'; then
        echo "${trimmed},${hooks_inner}}"
    else
        echo "{${hooks_inner}}"
    fi
}

if [ -f "$SETTINGS_FILE" ]; then
    EXISTING=$(cat "$SETTINGS_FILE")

    # Check if hooks already configured
    if echo "$EXISTING" | grep -q "agents-monitor-hook.sh"; then
        info "Agents Monitor hooks already configured — skipping"
    else
        if command -v jq &>/dev/null; then
            MERGED=$(merge_hooks "$EXISTING" "$HOOKS_TEMPLATE")
            echo "$MERGED" | jq '.' > "$SETTINGS_FILE"
            info "Merged hooks into $SETTINGS_FILE"
        else
            RESULT=$(merge_hooks_no_jq "$EXISTING")
            echo "$RESULT" > "$SETTINGS_FILE"
            info "Added hooks to $SETTINGS_FILE"
        fi
    fi
else
    # No existing settings — just copy our hooks as the settings file
    cp "$HOOKS_TEMPLATE" "$SETTINGS_FILE"
    info "Created $SETTINGS_FILE with hooks"
fi

# ── Launch ─────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Launching Agents Monitor...${NC}"
open "$APP_INSTALL_PATH"
info "Agents Monitor is running in your menu bar"

# ── Login Item hint ────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Optional: Start on login${NC}"
echo "  System Settings → General → Login Items → add Agents Monitor"

# ── Done ───────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "  Menu bar icons:"
echo "    ● Grey     — no active sessions"
echo "    ● Green    — agent is working"
echo "    ● Orange   — agent needs your attention"
echo ""
echo "  Start a Claude Code session to see it in action."
echo "  To uninstall: ./uninstall.sh"
echo ""
