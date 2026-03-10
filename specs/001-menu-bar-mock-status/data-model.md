# Data Model: Menu Bar App with Mock Status Cycle

**Date**: 2026-03-10
**Feature**: 001-menu-bar-mock-status

## Entities

### StatusState (Enum)

Represents the aggregated monitoring status displayed in the menu
bar icon.

| Value       | Visual             | Animation   |
|-------------|--------------------|-------------|
| `idle`      | Grey circle        | None (static) |
| `running`   | Green circle       | Flashing (~1 Hz) |
| `attention` | Orange circle      | Flashing (~1 Hz) |

**Priority order** (for future aggregation across instances):
`attention` > `running` > `idle`

### StatusProvider (Protocol)

Abstraction for the source of status data. Separates transport
from presentation per Constitution Principle II.

| Property/Method       | Description                          |
|-----------------------|--------------------------------------|
| `currentStatus`       | The current `StatusState` value      |
| (observable)          | Must trigger UI updates on change    |

**MVP implementation**: `MockStatusProvider` — cycles through
`idle → running → attention` on a 3-second timer.

**Future implementation**: `ClaudeCodeStatusProvider` — reads
real Claude Code instance states from filesystem/process
inspection and aggregates per Constitution Principle III.

## State Transitions (Mock Provider)

```text
┌──────────┐  3s   ┌──────────┐  3s   ┌───────────┐
│   idle   │──────▶│ running  │──────▶│ attention │
│  (grey)  │       │ (green)  │       │ (orange)  │
└──────────┘       └──────────┘       └───────────┘
      ▲                                     │
      └─────────────────────────────────────┘
                       3s
```

## Relationships

```text
App ──observes──▶ StatusProvider ──publishes──▶ StatusState
 │                      ▲
 └──renders──▶ MenuBarIcon (color + animation from StatusState)
                        │
              MockStatusProvider (this feature)
              ClaudeCodeStatusProvider (future)
```
