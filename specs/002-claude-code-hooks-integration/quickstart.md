# Quickstart: Claude Code Hooks Integration

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (with Swift 5.9+)
- Claude Code CLI installed and working
- `jq` recommended (install via `brew install jq`); not strictly required

## Build & Run the App

1. Open `ClaudeMonitor.xcodeproj` in Xcode (or `swift build` via SPM).
2. Select the `ClaudeMonitor` scheme and `My Mac` as the run destination.
3. Press **Cmd+R** to build and run.
4. Verify: a grey circle appears in the menu bar (no active sessions).

## Install Hook Configuration

1. Copy the hook script to your Claude config:

   ```bash
   mkdir -p ~/.claude/hooks
   cp scripts/claude-monitor-hook.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/claude-monitor-hook.sh
   ```

2. Add the hook configuration to `~/.claude/settings.json`. If you
   already have a `hooks` section, merge the entries (don't replace):

   ```json
   {
     "hooks": {
       "SessionStart": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh running" }] }
       ],
       "UserPromptSubmit": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh running" }] }
       ],
       "PreToolUse": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh running" }] }
       ],
       "PostToolUse": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh running" }] }
       ],
       "Stop": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh attention" }] }
       ],
       "PermissionRequest": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh attention" }] }
       ],
       "Notification": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh attention" }] }
       ],
       "SessionEnd": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "~/.claude/hooks/claude-monitor-hook.sh idle" }] }
       ]
     }
   }
   ```

3. Restart any running Claude Code sessions for hooks to take effect.

## Test the Integration

1. **Start the app** — grey icon in menu bar.
2. **Start a Claude Code session** — icon turns steady green.
3. **Wait for Claude to finish responding** — icon turns flashing orange.
4. **Type a prompt** — icon turns back to steady green.
5. **Exit the Claude Code session** (`/exit`) — icon returns to grey.

## Verify Success

- [ ] Grey icon when no Claude Code session is running
- [ ] Green (steady, not flashing) when Claude is processing
- [ ] Flashing orange when Claude is waiting for input
- [ ] Transitions happen within ~1 second
- [ ] Multiple concurrent sessions: orange takes priority over green
- [ ] App not running: Claude Code still works normally (hooks fail silently)
- [ ] Menu dropdown shows session count (e.g., "1 session active")
- [ ] Quit from menu works cleanly

## Troubleshooting

- **Icon stays grey**: Check that the hook script is executable
  (`chmod +x`) and the socket path `/tmp/claude-monitor.sock` exists
  (created by the app on launch).
- **Hook errors**: Test the hook script manually:
  `echo '{"session_id":"test","cwd":"/tmp"}' | bash ~/.claude/hooks/claude-monitor-hook.sh running`
  Should exit 0 with no output.
- **Multiple apps**: Only one instance of Claude Monitor should run
  at a time (the socket path is shared).
