# Research: Claude Code Hooks Integration

**Date**: 2026-03-10
**Feature**: 002-claude-code-hooks-integration

## R1: Communication Channel Between Hooks and App

**Decision**: Unix domain socket at a well-known path (`/tmp/claude-monitor.sock`)

**Rationale**: Hook scripts need to send state events to the menu bar
app with minimal latency and zero external dependencies. A Unix
domain socket is the simplest IPC mechanism available on macOS:
- No port conflicts (unlike localhost HTTP)
- No dependency on `curl` or HTTP libraries in the hook script
- Sub-millisecond delivery — meets the <100ms hook execution target
- The hook script can write a short JSON payload via `nc -U` or
  direct file descriptor write and exit immediately
- The app listens with `NWListener` (Network.framework) on the
  socket path

**Alternatives considered**:
- Localhost HTTP server (e.g., `NWListener` with HTTP): Requires HTTP
  parsing overhead, port allocation, and `curl` in the hook script.
  More fragile with port conflicts.
- Shared file (e.g., `/tmp/claude-monitor-state.json`): Requires
  polling from the app side, adding latency. File locking is
  error-prone with concurrent writers.
- Distributed Notifications (`DistributedNotificationCenter`): macOS
  API but not easily callable from a bash hook script without a
  helper binary. Adds complexity.

## R2: Claude Code Hook Events and State Mapping

**Decision**: Map Claude Code hook events to app states as follows:

| Hook Event          | Matcher               | App State  | Rationale                                   |
|---------------------|-----------------------|------------|---------------------------------------------|
| `SessionStart`      | (any)                 | `running`  | Session initialized, Claude is active       |
| `UserPromptSubmit`  | (any)                 | `running`  | User sent input, Claude is processing       |
| `PreToolUse`        | (any)                 | `running`  | Tool about to execute                       |
| `PostToolUse`       | (any)                 | `running`  | Tool completed, Claude continues            |
| `Stop`              | (any)                 | `attention`| Claude finished responding, waiting for next prompt |
| `PermissionRequest` | (any)                 | `attention`| Permission dialog shown, user must respond  |
| `Notification`      | (any)                 | `attention`| Claude needs user attention                 |
| `SessionEnd`        | (any)                 | `idle`     | Session terminated                          |

**Key insight**: The `Stop` event means Claude finished its response
and is now waiting for the user's next prompt. This is an "attention"
state because the user needs to provide input. The `UserPromptSubmit`
event fires when the user provides that input, transitioning back to
`running`.

**Rationale**: This mapping covers the full session lifecycle. The
`Stop` → `attention` mapping ensures the icon correctly shows orange
whenever Claude is waiting, whether for a permission prompt or the
next user message.

**Alternatives considered**:
- Mapping `Stop` to `idle`: Would make the icon go grey between each
  turn, which is misleading — the session is still active and waiting.
- Mapping `Stop` to `running`: Would show green when Claude isn't
  doing anything, defeating the purpose.

## R3: Hook Script Design

**Decision**: Single bash script (`claude-monitor-hook.sh`) that
receives the event type as the first argument and reads JSON from
stdin. Sends a compact JSON message to the Unix socket.

**Rationale**: A single script keeps configuration simple (one
command path for all events). The script uses `echo` piped to
`nc -U` for socket communication. If the socket is unavailable
(app not running), `nc` fails silently and the script exits 0.

**Message format**:
```json
{"sid":"<session_id>","state":"running|attention|idle","cwd":"<dir>","ts":<unix_timestamp>}
```

**Script behavior**:
1. Read first argument (mapped state: `running`, `attention`, `idle`)
2. Read JSON from stdin, extract `session_id` and `cwd` via `jq`
   (fallback: basic string extraction if `jq` unavailable)
3. Send JSON to `/tmp/claude-monitor.sock` via `nc -U`
4. Exit 0 immediately regardless of success/failure

## R4: Stale Session Detection

**Decision**: Timer-based cleanup with 5-minute timeout

**Rationale**: If a Claude Code session crashes or is killed without
firing `SessionEnd`, the app needs to clean up the stale entry. A
simple approach: each event updates a `lastEventTime` timestamp per
session. A periodic timer (every 30 seconds) removes sessions whose
`lastEventTime` is older than 5 minutes.

**Alternatives considered**:
- Process monitoring (check if PID alive): Would require the hook
  to send the PID, and macOS sandbox may restrict process inspection.
  Over-engineered for MVP.
- Heartbeat mechanism: Would require a continuously-running hook,
  which contradicts the "fire and exit" hook model.

## R5: Green Icon Animation Change

**Decision**: Change `running` state `isAnimated` from `true` to `false`

**Rationale**: The user explicitly requested "Green should not blink,
only orange." The current `StatusState.isAnimated` returns `true` for
both `running` and `attention`. This must be changed so only
`attention` flashes.

**Note**: This deviates from Constitution Principle III which states
"Flashing green: Any instance is actively running." This is a
deliberate user override. A constitution amendment (PATCH) should be
filed to align the constitution with the desired behavior.

## R6: Socket Listener Implementation

**Decision**: Use `NWListener` from Network.framework with
`.unix(path:)` endpoint

**Rationale**: Network.framework is Apple's modern networking API,
available on macOS 14+. `NWListener` supports Unix domain sockets
natively, handles concurrent connections, and integrates with GCD
for main-thread dispatching. No third-party dependencies.

**Connection handling**:
1. Accept connection
2. Read data until connection closes (hook sends one message and
   disconnects)
3. Parse JSON and update session state
4. Close connection

**Alternatives considered**:
- POSIX `socket()/bind()/listen()`: Lower-level, more boilerplate,
  no automatic GCD integration.
- `CFSocket`: Legacy API, more complex than NWListener.

## R7: `jq` Dependency in Hook Script

**Decision**: Use `jq` for JSON parsing in the hook script, with a
pure-bash fallback using `sed`/`grep`

**Rationale**: `jq` is the standard CLI JSON parser and is commonly
available on developer machines (installed via Homebrew). However, we
cannot assume it's present, so the script includes a fallback that
extracts `session_id` and `cwd` using basic string matching. The
fields are simple enough that regex extraction is reliable.
