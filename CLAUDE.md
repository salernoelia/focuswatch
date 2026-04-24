# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FocusWatch is a watchOS + iOS Swift app for users with focus difficulties. It has four targets:
- **`companion`** — iOS app (auth, checklist editing, calendar scheduling, progress visualization)
- **`watch`** — watchOS app (accelerometer/EMA writing detection, haptic feedback, focus tools)
- **`shared`** — Swift framework shared between both apps (data models, WatchConnectivity sync, Supabase)
- **`watch-notification`** / **`watch-version-complication`** — watchOS extensions

## Setup

1. `supabase start` in project root (requires Docker Desktop + Supabase CLI)
2. Copy `Example.xcconfig` to `Development.xcconfig`, populate `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_DRIVE_USERNAME`, `GOOGLE_DRIVE_PASSWORD`
3. Configure valid Developer Team in Xcode Signing & Capabilities for all targets

## Build & Run Commands

Don't trigger builds yourself. Makefile targets for reference:

```
make ios-build        # Build iOS scheme for simulator
make ios-test         # Run iOS tests (iPhone 17 sim)
make watch-build      # Build watchOS scheme for simulator
make watch-test       # Run watchOS tests (Apple Watch Series 11 46mm sim)
make dev              # Launch iOS + watch apps concurrently
make all-test         # Run both test suites
```

Simulator name overrides: `IOS_SIM_NAME`, `WATCH_SIM_NAME`, `IOS_TEST_SIM_NAME`, `WATCH_TEST_SIM_NAME`.

## Architecture

### Layer Structure

```
Watch App  ──WatchConnectivity──  Companion App
     └──────── shared framework ──────────┘
                      │
               Supabase API (telemetry, auth, feedback)
```

- The project uses folder-based references (no individual .swift entries in the pbxproj), so new files are picked up automatically. 

### Data Persistence

- **`ChecklistDataStore`** (`companion/Services/ChecklistDataStore.swift`) — UserDefaults persistence for checklists, zero sync logic, debounced 0.5s saves. The UI binds here; `SyncCoordinator` reads from here when pushing to watch.
- **SwiftData models** — `LevelProgress`, `ActivityStats`, `Event` (in `shared/Models/`)
- **Shared UserDefaults** — App Group `group.net.com.fokusuhr` for widget/complication access
- **Document directory** — Gallery images (UUID-named, resized to 300×300, JPEG 0.2 quality)
- **Keychain** — Auth tokens via `KeychainAccess` package

### Key Services

- `shared/Services/LevelService.swift` — XP/level-up logic, `@MainActor` singleton, notifies iOS of watch-side XP gains
- `companion/Services/GalleryStorage.swift` — Image resizing, compression, debounced persistence
- `watch/Services/GalleryManager.swift` — Receives transferred files from iOS

### Sync Architecture

`SyncCoordinator` (companion) owns a `SyncCommandRouter` and all per-domain sync services (`CalendarSyncService`, `ChecklistSyncService`, `LevelSyncService`, `ConfigSyncService`, `AuthSyncService`, `TelemetrySyncService`, `CommandSyncService`, `ImageSyncService`). Each service registers its action handlers on the router. Messages cross the WatchConnectivity boundary as `SyncPacket` (typed, JSON-encoded) using `SyncTransportProtocol` — the production impl is `ConnectivityTransportAdapter`.

Watch-side receives via `shared/Connectivity/` and routes through the same router pattern. New sync domains must: add a key to `SyncConstants.Keys`, an action to `SyncConstants.Actions`, register a handler on `SyncCommandRouter`, and handle both send and receive sides.

### Watch Feature Views

`watch/Views/` contains standalone focus tools: `Writing/` (EMA writing detection), `Pomodoro/`, `ColorBreathing/`, `FidgetToy/`, `Speedometer/`, `Level/`, `Checklist/`, `Calendar/`, `Progress/`, `Settings/`, `Dashboard/`.

### Writing Detection (Watch)

EMA-based accelerometer model in `watch/Views/Writing/`. `EmaModel` processes motion samples; `WritingMotionManager`, `WritingTimeManager`, and `WritingHapticFeedbackManager` handle the subsystems.

## Development Standards

- **Dependency Injection over Singletons** — prefer DI to make code testable; only existing singletons are justified by platform constraints.
- **async/await over GCD** — use Swift Structured Concurrency; avoid `DispatchQueue` for new code.
- **No magic strings** — all storage keys and hardcoded values belong in `AppConstants` or `SyncConstants`.
- **Logging** — use `AppLogger` for telemetry events, `ErrorLogger` for debug/error logging.
- **Tests** — use Swift Testing (`@Suite`, `@Test`, `#expect`), not XCTest. Test targets: `watch-testing`, `companion-testing`.
- **Branching** — `feature/issue-number-description` or `fix/issue-number-description`; no direct commits to `main`; PRs must reference an open issue.
- All tests must pass before merging.
- Make sure new features or adjustments dont break backwards compatibility
- Never use emojis
- Do not do any code comments