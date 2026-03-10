<!--
  Sync Impact Report
  ==================
  Version change: 0.0.0 → 1.0.0 (initial ratification)

  Modified principles: N/A (initial creation)

  Added sections:
    - Core Principles (5 principles)
    - Technology & Platform Constraints
    - Development Workflow
    - Governance

  Removed sections: N/A

  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ compatible (no changes needed)
    - .specify/templates/spec-template.md ✅ compatible (no changes needed)
    - .specify/templates/tasks-template.md ✅ compatible (no changes needed)

  Follow-up TODOs: None
-->

# Claude Monitor Constitution

## Core Principles

### I. Native macOS Menu Bar App

The application MUST be a native macOS menu bar (NSStatusItem) app
distributed as a standalone installable `.app` bundle. It MUST use
Swift and SwiftUI/AppKit for all UI. No Electron, no web wrappers,
no cross-platform frameworks. The app MUST run as a background agent
(LSUIElement) with no Dock icon — its only visible presence is the
menu bar icon.

**Rationale**: A status indicator must be lightweight and
unobtrusive. Native implementation ensures minimal resource usage
and seamless macOS integration.

### II. Extensible Data Architecture

All Claude Code instance data MUST flow through a single, versioned
data model that separates **transport** (how data arrives) from
**presentation** (how data is displayed). New data fields (e.g.,
running agents, tool call counts) MUST be addable without modifying
existing consumers. The data model MUST support multiple concurrent
Claude Code instances, each uniquely identified.

**Rationale**: The MVP shows only idle/running/attention status, but
the architecture must accommodate richer per-instance telemetry
without rewrites.

### III. Clear Status Hierarchy

The menu bar icon MUST reflect a single aggregated status across all
monitored Claude Code instances using these rules:

- **Grey circle**: All instances idle (or no instances detected)
- **Flashing orange**: Any instance requires user attention
  (highest priority)
- **Flashing green**: Any instance is actively running (and none
  require attention)

Orange MUST take precedence over green. This priority ordering MUST
be maintained as new statuses are added in the future.

**Rationale**: A single glanceable icon must convey the most
actionable state without ambiguity.

### IV. Minimal Footprint

The app MUST consume negligible system resources: < 50 MB memory,
< 1% CPU when polling. Polling intervals MUST be configurable but
default to a reasonable frequency (e.g., 1–2 seconds). The app MUST
NOT require elevated permissions, network access, or modifications
to Claude Code itself to function.

**Rationale**: A monitoring tool must never become a burden on the
system it monitors.

### V. Simplicity First

Start with the simplest implementation that works. No premature
abstractions, no plugin systems, no configuration UI beyond what
the MVP requires. Each feature MUST be justified by a concrete user
need. Complexity MUST be deferred until actually required by a
planned feature — not by hypothetical future needs.

**Rationale**: The MVP is a status light. Overengineering defeats
the purpose of a quick-glance utility.

## Technology & Platform Constraints

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI for menu/popover content, AppKit for
  NSStatusItem integration
- **Target**: macOS 14 (Sonoma) and later
- **Distribution**: Direct `.app` bundle (DMG or ZIP); App Store
  distribution is NOT required for MVP
- **Build System**: Xcode / Swift Package Manager
- **Data Source**: Claude Code status MUST be read from local
  filesystem or process inspection — no network calls to external
  services for status data
- **Testing**: XCTest for unit tests; UI testing optional for MVP

## Development Workflow

- All code changes MUST be committed with clear, descriptive
  messages
- Features MUST be developed behind user stories with defined
  acceptance criteria
- The menu bar icon behavior (color, animation) MUST be verified
  manually or via UI tests before any status-related PR is merged
- Code MUST compile without warnings on the target Swift version

## Governance

This constitution defines the non-negotiable principles for the
Claude Monitor project. All design decisions, implementation plans,
and code reviews MUST verify compliance with these principles.

**Amendment procedure**: Any principle change MUST be documented
with rationale, receive explicit approval, and include a migration
plan if it affects existing code. Version MUST be incremented per
semantic versioning (MAJOR for principle removals/redefinitions,
MINOR for additions, PATCH for clarifications).

**Compliance review**: Each spec and plan MUST include a
Constitution Check section verifying alignment with all five
principles.

**Version**: 1.0.0 | **Ratified**: 2026-03-10 | **Last Amended**: 2026-03-10
