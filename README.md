# Claude Monitor

A macOS menu bar app that shows the status of your Claude Code sessions at a glance.

![Version 0.1.0](https://img.shields.io/badge/version-0.1.0-green)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)

## What it does

Claude Monitor sits in your menu bar and shows a colored dot indicating what Claude Code is doing across all your terminal sessions:

| Icon | Meaning |
|------|---------|
| **Grey** | No active sessions |
| **Green** | Claude is processing |
| **Orange (flashing)** | Claude needs your attention (permission request, waiting for input) |

When Claude needs attention, you get a macOS notification. Click it to jump straight to the right terminal window.

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+ (included with Xcode 15+, or install via `xcode-select --install`)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` recommended (`brew install jq`) — used for safe config merging

## Setup

```bash
git clone https://github.com/anthropics/claude-monitor.git
cd claude-monitor
./setup.sh
```

That's it. The setup script will:

1. Build the app from source
2. Install it to `/Applications`
3. Copy the hook script to `~/.claude/hooks/`
4. Merge hook config into `~/.claude/settings.json`
5. Launch Claude Monitor

Start a Claude Code session to see it in action.

### Start on login (optional)

System Settings > General > Login Items > add **Claude Monitor**

## Uninstall

```bash
./uninstall.sh
```

Removes the app, hook script, and hook configuration from your Claude Code settings.

## How it works

Claude Code [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) fire on session lifecycle events (start, stop, tool use, permission request, etc.). A lightweight shell script receives these events and forwards them to the menu bar app over a Unix socket (`/tmp/claude-monitor.sock`). The app aggregates state across all sessions and renders the appropriate status icon.

## Architecture

```
Claude Code ──hook──> claude-monitor-hook.sh ──socket──> ClaudeMonitor.app (menu bar)
```

- **Hook script** (`~/.claude/hooks/claude-monitor-hook.sh`): Reads hook event JSON from stdin, extracts session info, sends compact JSON to the Unix socket
- **Menu bar app** (`ClaudeMonitor.app`): Listens on the socket, tracks sessions, renders status icon, sends notifications

## Development

```bash
# Build and run directly
swift build && .build/debug/ClaudeMonitor

# Build release app bundle
./scripts/bundle-app.sh
open build/ClaudeMonitor.app
```

## License

MIT
