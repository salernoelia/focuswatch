# Level System

A watchOS leveling system that rewards users with XP (experience points) for completing activities in the FokusUhr platform.

## Architecture

### Models
- **LevelProgress** (`Shared/Models/LevelProgress.swift`): SwiftData model storing user progress
  - `currentLevel`: Current user level (starts at 1)
  - `currentXP`: XP accumulated toward next level
  - `totalXP`: Lifetime XP earned
  - `lastUpdated`: Timestamp of last update

### Services
- **LevelService** (`Services/LevelService.swift`): Main service managing level progression
  - Singleton pattern with `LevelService.shared`
  - Handles XP calculation, level ups, notifications, and haptic feedback
  - SwiftData persistence

- **LevelService+Activities** (`Services/LevelService+Activities.swift`): Extension providing activity-based XP rewards
  - Predefined activity types with appropriate XP values
  - Easy integration for apps

### ViewModels
- **LevelViewModel** (`Views/Level/LevelViewModel.swift`): Observable view model for UI
  - Publishes level, XP, and progress values
  - Singleton pattern with `LevelViewModel.shared`

### Views
- **LevelView** (`Views/Level/LevelView.swift`): Main user-facing level display
  - Minimal, Apple-native design
  - Animated progress bar with gradient
  - Shows current level, XP, and progress percentage
  - Debug tools accessible only in DEBUG builds

- **LevelDebugView** (`Views/Level/LevelDebugView.swift`): Debug interface
  - Award XP in various amounts
  - View current stats
  - Reset progress

## XP System

### Level Formula
XP required for level N: `N × 100`
- Level 2: 200 XP
- Level 3: 300 XP
- Level 10: 1000 XP

### Activity Rewards
| Activity | XP | ActivityType |
|----------|----|----|
| Pomodoro Completed | 100 | `.pomodoroCompleted` |
| Writing Session | 75 | `.writingSession` |
| Checklist Completed | 50 | `.checklistCompleted` |
| Journal Entry | 40 | `.journalEntry` |
| Breathing Exercise | 30 | `.breathingExercise` |
| Calendar Event Created | 25 | `.calendarEventCreated` |
| Fidget Used | 10 | `.fidgetUsed` |

## Integration Guide

### Award XP for Activity

```swift
LevelService.shared.awardXP(for: .checklistCompleted)
LevelService.shared.awardXP(for: .pomodoroCompleted)
```

### Custom XP Amount

```swift
LevelService.shared.awardXP(for: .custom, customAmount: 150)
```

### Direct XP Addition

```swift
LevelService.shared.addXP(50, reason: "Special achievement")
```

## Features

### Level Up
- Double haptic feedback (success vibration)
- System notification with level announcement
- Automatic XP overflow handling

### Notifications
- Category: `LEVEL_UP`
- Title: "Level {N} erreicht!"
- Body: "Du hast ein neues Level freigeschaltet!"

### Haptics
- XP gain: `.click`
- Level up: `.success` (x2)

### Persistence
- SwiftData automatic persistence
- Survives app restarts
- Integrated with existing ModelContainer

## Example Integration

```swift
case .completed:
  ChecklistCompletionView()
    .onAppear {
      LevelService.shared.awardXP(for: .checklistCompleted)
    }
```

## Debug Mode

Access debug tools in LevelView (DEBUG builds only):
- Award test XP: 10, 50, 100, 500
- View total lifetime XP
- Reset all progress

## Technical Notes

- Thread-safe with `@MainActor`
- Error logging for debug builds
- Minimal external dependencies
- No crashes on edge cases
- Efficient SwiftData queries
