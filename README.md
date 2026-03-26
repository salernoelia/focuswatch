# FocusWatch

FocusWatch helps users with focus difficulties through biometric feedback and structured routines. It consists of a watchOS app for real-time interaction and an iOS companion app for configuration and progress tracking.

## Architecture

Built with Swift and SwiftUI across four layers:

| Component | Responsibility |
|---|---|
| Watch App | Accelerometer processing, haptic feedback, standalone focus tools |
| Companion App | Authentication, checklist creation, calendar scheduling, progress visualization |
| Shared Framework | Data models, WatchConnectivity sync, Supabase integration |
| Supabase API | Telemetry logging and feedback persistence |


## Features

#### Writing Detection
EMA-based biometric model identifies focus states and delivers corrective haptic feedback.

#### Interactive Checklists
Offline-capable routines with image support, synced across devices.

#### Scheduled Routines
Calendar system that triggers watch apps based on predefined reminders.

#### Leveling System
Gamified consistency tracking with XP and milestones.

#### Focus Tools
Pomodoro timer, color-breathing exercises, fidget mod


## Setup

**Prerequisites:** macOS, Xcode, Docker Desktop, [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)

1. Run `supabase start` in the project root.
2. Copy `Example.xcconfig` to `Development.xcconfig` and populate it with your Supabase URL and API keys.
3. In Xcode, configure a valid Developer Team under Signing & Capabilities for all targets.
4. Use an iPhone + Apple Watch simulator, or a physical iPhone paired with an Apple Watch.

## Maintainers

- Elia Salerno
- Ege Seçgin