# Data Model: Claude Code Hooks Integration

**Date**: 2026-03-10
**Feature**: 002-claude-code-hooks-integration

## Entities

### StatusState (Enum) — Updated

Represents the monitoring status. **Change from 001**: `running`
is no longer animated (green is steady, only orange flashes).

| Value       | Visual             | Animation       |
|-------------|--------------------|-----------------|
| `idle`      | Grey circle        | None (static)   |
| `running`   | Green circle       | None (steady)   |
| `attention` | Orange circle      | Flashing (~1 Hz)|

**Priority order**: `attention` > `running` > `idle`

### SessionInfo (New)

Represents a single tracked Claude Code session.

| Field            | Type          | Description                                      |
|------------------|---------------|--------------------------------------------------|
| `sessionId`      | String        | Unique session ID from Claude Code               |
| `state`          | StatusState   | Current state of this session                    |
| `workingDir`     | String        | Project directory for this session               |
| `lastEventTime`  | Date          | Timestamp of last received event                 |

### StateEvent (New)

A message received from a Claude Code hook via the Unix socket.

| Field            | Type          | Description                                      |
|------------------|---------------|--------------------------------------------------|
| `sid`            | String        | Session ID (`session_id` from hook JSON)         |
| `state`          | String        | Mapped state: `"running"`, `"attention"`, `"idle"` |
| `cwd`            | String        | Working directory of the session                 |
| `ts`             | Int           | Unix timestamp of the event                      |

**Wire format** (JSON over Unix socket):
```json
{"sid":"abc123","state":"running","cwd":"/Users/dev/project","ts":1741564800}
```

### SessionManager (New)

Tracks all active sessions and computes the aggregate state.

| Property/Method       | Description                                      |
|-----------------------|--------------------------------------------------|
| `sessions`            | Dictionary of `sessionId → SessionInfo`          |
| `aggregateState`      | Computed: highest-priority state across sessions  |
| `handleEvent(_:)`     | Updates or creates a session from a StateEvent   |
| `cleanupStaleSessions()` | Removes sessions older than timeout threshold |

### HookStatusProvider (New)

Concrete implementation of `StatusProvider` protocol. Replaces
`MockStatusProvider` for real Claude Code monitoring.

| Property/Method       | Description                                      |
|-----------------------|--------------------------------------------------|
| `currentStatus`       | Returns `SessionManager.aggregateState`          |
| `sessionManager`      | Owns the `SessionManager` instance               |
| `socketListener`      | Owns the `NWListener` for Unix socket            |

## State Transitions (Per Session)

```text
                    SessionStart / UserPromptSubmit / PreToolUse / PostToolUse
                    ┌───────────────────────────────────────────────────┐
                    ▼                                                   │
              ┌──────────┐    Stop / PermissionRequest    ┌───────────┐│
  SessionStart│ running  │──────────────────────────────▶│ attention ││
              │ (green)  │                                │ (orange)  ││
              └──────────┘                                └───────────┘│
                    ▲                                          │       │
                    │         UserPromptSubmit                 │       │
                    └─────────────────────────────────────────┘       │
                                                                      │
              ┌──────────┐    SessionEnd                              │
              │   idle   │◀───────────────────────────────────────────┘
              │  (grey)  │◀─── timeout (5 min no events)
              └──────────┘
```

## Aggregate State Logic

```text
Given all sessions S:
  If S is empty → idle
  If any s in S has state == attention → attention
  If any s in S has state == running → running
  Otherwise → idle
```

## Relationships

```text
App ──observes──▶ HookStatusProvider ──delegates──▶ SessionManager
 │                      │                                │
 │                      │                                ├── sessions: [SessionInfo]
 │                      │                                └── aggregateState: StatusState
 │                      │
 │                      └── socketListener (NWListener on /tmp/claude-monitor.sock)
 │                              │
 │                              └── receives StateEvent JSON from hook scripts
 │
 └──renders──▶ MenuBarIcon (color + animation from StatusState)

Hook Scripts ──send──▶ Unix Socket ──parsed by──▶ HookStatusProvider
```
