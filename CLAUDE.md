# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FocusWatch is a watchOS + iOS Swift app for users with focus difficulties. It has four targets:
- **`companion`** — iOS app (auth, checklist editing, calendar scheduling, progress visualization)
- **`watch`** — watchOS app (accelerometer/EMA writing detection, haptic feedback, focus tools)
- **`shared`** — Swift framework shared between both apps (data models, WatchConnectivity sync, Supabase)
- **`watch-notification`** / **`watch-version-complication`** — watchOS extensions

## Build & Run Commands

Don't trigger builds yourself.

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

### Writing Detection (Watch)

EMA-based accelerometer model in `watch/Views/Writing/`. `EmaModel` processes motion samples; `WritingMotionManager`, `WritingTimeManager`, and `WritingHapticFeedbackManager` handle the subsystems.

## Development Standards

- **Dependency Injection over Singletons** — prefer DI to make code testable; only existing singletons are justified by platform constraints.
- **async/await over GCD** — use Swift Structured Concurrency; avoid `DispatchQueue` for new code.
- **No magic strings** — all storage keys and hardcoded values belong in `AppConstants` or `SyncConstants`.
- **Logging** — use `AppLogger` for telemetry events, `ErrorLogger` for debug/error logging.
- **Branching** — `feature/issue-number-description` or `fix/issue-number-description`; no direct commits to `main`; PRs must reference an open issue.
- All tests must pass before merging.
- Make sure new features or adjustments dont break backwards compatibility
- Never use emojis