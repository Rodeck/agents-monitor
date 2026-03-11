# Hook Event Schema (Extended)

**Feature**: 003-status-notifications
**Date**: 2026-03-11

## Socket Event JSON Schema

The hook script sends JSON messages to `/tmp/claude-monitor.sock`. This feature extends the existing schema with optional fields for parent application identification.

### Schema

```json
{
  "sid": "<string, required>",
  "state": "<string, required: running|attention|idle>",
  "cwd": "<string, required: absolute path>",
  "ts": "<integer, required: unix timestamp>",
  "ppid": "<integer, optional: terminal app process ID>",
  "app": "<string, optional: terminal app identifier>"
}
```

### Example Messages

**Terminal.app session needing attention:**
```json
{
  "sid": "abc123-def456",
  "state": "attention",
  "cwd": "/Users/dev/my-project",
  "ts": 1741651200,
  "ppid": 12345,
  "app": "com.apple.Terminal"
}
```

**VS Code session running:**
```json
{
  "sid": "xyz789-ghi012",
  "state": "running",
  "cwd": "/Users/dev/other-project",
  "ts": 1741651201,
  "ppid": 67890,
  "app": "com.microsoft.VSCode"
}
```

**Legacy event (no parent info, backward compatible):**
```json
{
  "sid": "abc123-def456",
  "state": "attention",
  "cwd": "/Users/dev/my-project",
  "ts": 1741651200
}
```

### Known App Identifiers

| Application | Bundle Identifier | Support Level |
|-------------|-------------------|---------------|
| Terminal.app | com.apple.Terminal | First-class |
| VS Code | com.microsoft.VSCode | First-class |
| iTerm2 | com.googlecode.iterm2 | First-class |
| Others | Process name fallback | Best-effort |

### Backward Compatibility

- `ppid` and `app` fields are optional
- Existing hook scripts without these fields continue to work
- Missing parent info means window focusing falls back to generic app activation
- No breaking changes to the existing `StateEvent` decoding
