# Contract: Claude Monitor Socket Protocol

**Version**: 1.0
**Transport**: Unix domain socket at `/tmp/claude-monitor.sock`
**Direction**: Hook script → Claude Monitor app (one-way)

## Connection Model

- **Client** (hook script): Connects, sends one JSON message, disconnects.
- **Server** (Claude Monitor app): Listens, accepts connections, reads
  until EOF, parses JSON, closes connection.
- No response is sent back to the client.
- If the socket does not exist or connection fails, the client MUST
  exit silently with code 0.

## Message Format

A single JSON object, newline-terminated:

```json
{"sid":"<string>","state":"<string>","cwd":"<string>","ts":<integer>}\n
```

### Fields

| Field   | Type    | Required | Description                              |
|---------|---------|----------|------------------------------------------|
| `sid`   | String  | Yes      | Claude Code session ID                   |
| `state` | String  | Yes      | One of: `"running"`, `"attention"`, `"idle"` |
| `cwd`   | String  | Yes      | Working directory of the session         |
| `ts`    | Integer | Yes      | Unix timestamp (seconds since epoch)     |

### State Values

| Value       | Meaning                                    |
|-------------|--------------------------------------------|
| `running`   | Session is actively processing             |
| `attention` | Session is waiting for user input          |
| `idle`      | Session has ended                          |

## Example Messages

```json
{"sid":"sess_abc123","state":"running","cwd":"/Users/dev/myproject","ts":1741564800}
{"sid":"sess_abc123","state":"attention","cwd":"/Users/dev/myproject","ts":1741564810}
{"sid":"sess_abc123","state":"idle","cwd":"/Users/dev/myproject","ts":1741564900}
```

## Error Handling

- Unknown `state` values MUST be ignored by the app (forward compatibility).
- Malformed JSON MUST be silently discarded.
- Missing fields MUST cause the message to be discarded.
