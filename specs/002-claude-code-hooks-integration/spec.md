# Feature Specification: Claude Code Hooks Integration

**Feature Branch**: `002-claude-code-hooks-integration`
**Created**: 2026-03-10
**Status**: Draft
**Input**: User description: "Integrate app with Claude Code via hooks to show real-time session state in the menu bar — green when running, flashing orange when requiring user input, grey when no active session."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Live Session State in Menu Bar (Priority: P1)

As a developer using Claude Code, I want the Claude Monitor menu bar icon to automatically reflect the current state of my Claude Code session so I can glance at the menu bar and know whether Claude is working, needs my attention, or is idle — without switching to the terminal.

- **Grey icon**: No active Claude Code session
- **Green icon (steady)**: Claude Code is actively processing (running tools, generating responses)
- **Orange icon (flashing)**: Claude Code is waiting for user input (permission prompts, questions, idle prompt)

**Why this priority**: This is the core value proposition — real-time visual feedback of Claude Code session state. Without this, the app has no integration.

**Independent Test**: Can be fully tested by starting a Claude Code session and observing the menu bar icon transition from grey to green, then triggering a permission prompt and verifying the icon flashes orange, and finally ending the session to see it return to grey.

**Acceptance Scenarios**:

1. **Given** no Claude Code session is active, **When** I look at the menu bar, **Then** I see a grey icon (steady, not animated)
2. **Given** a Claude Code session is active and processing, **When** Claude is running tools or generating a response, **Then** I see a green icon (steady, not flashing)
3. **Given** a Claude Code session is active, **When** Claude presents a permission prompt or waits for user input, **Then** I see an orange icon that flashes
4. **Given** a Claude Code session is in the "waiting for input" state, **When** the user provides input and Claude resumes processing, **Then** the icon transitions back to green (steady)
5. **Given** a Claude Code session is active, **When** the session ends, **Then** the icon transitions back to grey

---

### User Story 2 - Multiple Session Awareness (Priority: P2)

As a developer running multiple Claude Code sessions (e.g., in different terminal tabs or projects), I want the menu bar icon to reflect the aggregate state so I know if any session needs attention.

- If any session is waiting for input, show flashing orange (highest priority)
- If any session is running (and none waiting), show steady green
- If all sessions have ended, show grey

**Why this priority**: Power users commonly run multiple sessions. The icon should surface the most urgent state.

**Independent Test**: Can be tested by starting two Claude Code sessions, having one wait for input while the other runs, and verifying the icon shows flashing orange. Then resolving the input and verifying it transitions to green.

**Acceptance Scenarios**:

1. **Given** two active sessions where one is running and one is waiting for input, **When** I look at the menu bar, **Then** I see flashing orange (attention state takes priority)
2. **Given** two active sessions both running, **When** I look at the menu bar, **Then** I see steady green
3. **Given** one session ends while another is still running, **When** I look at the menu bar, **Then** I see steady green (not grey)
4. **Given** all sessions have ended, **When** I look at the menu bar, **Then** I see grey

---

### User Story 3 - Hook Configuration for Testing (Priority: P1)

As a developer, I want a hook configuration file that I can add to my Claude Code settings so that my Claude Code instances report their state to the Claude Monitor app, enabling me to test the integration manually before building an automated installer.

**Why this priority**: Without the hook configuration, no integration is possible. This is an enabler for User Story 1.

**Independent Test**: Can be tested by copying the hook configuration into `~/.claude/settings.json`, starting a Claude Code session, and verifying that state change events are sent to the Claude Monitor app.

**Acceptance Scenarios**:

1. **Given** I have the hook configuration in my Claude Code settings, **When** I start a Claude Code session, **Then** the hooks fire and notify Claude Monitor of the session start
2. **Given** hooks are configured, **When** Claude Code encounters a permission prompt, **Then** the hooks notify Claude Monitor that the session is waiting for input
3. **Given** hooks are configured, **When** Claude Code finishes responding, **Then** the hooks notify Claude Monitor that the session has stopped
4. **Given** hooks are configured, **When** the session ends, **Then** the hooks notify Claude Monitor of the session end

---

### Edge Cases

- What happens when the Claude Monitor app is not running but hooks fire? The hook scripts should fail silently (exit 0) and not block Claude Code.
- What happens when a Claude Code session crashes or is killed without a clean SessionEnd? The app should detect stale sessions (e.g., via heartbeat timeout) and transition them to idle.
- What happens when the hook configuration conflicts with existing user hooks? The integration hooks should be additive — appended to existing hook arrays, not replacing them.
- What happens when multiple sessions fire state changes simultaneously? The app should process events atomically and always display the highest-priority aggregate state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST receive state change notifications from Claude Code sessions via a local communication channel
- **FR-002**: The app MUST display a grey icon when no active Claude Code sessions exist
- **FR-003**: The app MUST display a steady green icon when at least one session is actively processing and no sessions are waiting for input
- **FR-004**: The app MUST display a flashing orange icon when at least one session is waiting for user input
- **FR-005**: The app MUST transition between states within 1 second of receiving a state change event
- **FR-006**: The app MUST track multiple concurrent sessions independently, each identified by a unique session identifier
- **FR-007**: The app MUST aggregate session states using priority ordering: attention (orange) > running (green) > idle (grey)
- **FR-008**: The hook scripts MUST NOT block or delay Claude Code operations (exit immediately with code 0)
- **FR-009**: The hook scripts MUST fail silently if the Claude Monitor app is not running
- **FR-010**: The app MUST detect and clean up stale sessions that have not sent events within a configurable timeout period
- **FR-011**: The app MUST provide a testable hook configuration that users can manually add to their Claude Code settings
- **FR-012**: The green icon MUST NOT flash or animate — only the orange (attention) icon flashes

### Key Entities

- **Session**: Represents a single Claude Code session, identified by session ID, with a current state (idle, running, attention) and a last-event timestamp
- **State Event**: A notification from a Claude Code hook containing session ID, event type, timestamp, and working directory
- **Aggregate State**: The computed overall state derived from all active sessions, used to determine the menu bar icon display

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Menu bar icon reflects the correct Claude Code session state within 1 second of a state change
- **SC-002**: Users can set up the integration by adding a single configuration block to their Claude Code settings
- **SC-003**: Hook scripts complete execution in under 100 milliseconds, adding no perceptible delay to Claude Code operations
- **SC-004**: The app correctly tracks and aggregates state across at least 5 concurrent Claude Code sessions
- **SC-005**: Stale sessions (no events for the timeout period) are automatically transitioned to idle without manual intervention

## Assumptions

- Claude Code hooks system supports `SessionStart`, `Stop`, `PermissionRequest`, `Notification`, and `SessionEnd` events, and passes JSON payloads on stdin including `session_id`
- The app will listen on a local communication channel (e.g., localhost HTTP endpoint or Unix socket) for hook notifications
- The existing `StatusState` enum (`idle`, `running`, `attention`) and `StatusProvider` protocol in the app already model the required states correctly
- The `running` state's `isAnimated` property should be updated to `false` (currently `true` in the existing code) since green should not flash per user requirements
- The stale session timeout defaults to a reasonable period (e.g., 5 minutes) without requiring user configuration initially
