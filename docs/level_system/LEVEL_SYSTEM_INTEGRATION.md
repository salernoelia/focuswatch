# Level System Integration Guide

## Overview
The leveling system is designed to be flexible and extensible for future features. This guide shows how to integrate new apps and add custom rewards.

## Publishing Activities from Micro Apps

### Method 1: Using Predefined Activity Types (Recommended)
```swift
LevelService.shared.awardXP(for: .pomodoroCompleted)
LevelService.shared.awardXP(for: .checklistCompleted)
```

### Method 2: Using the Protocol (For New Apps)
```swift
class MyAppViewModel: ObservableObject, LevelSystemIntegration {
  var appName: String { "My App" }
  
  func completeTask() {
    publishActivity(name: "Task Completed", xpAmount: 50)
  }
}
```

### Method 3: Direct Publishing (Most Flexible)
```swift
LevelService.shared.publishActivity(
  appName: "Custom App",
  activityName: "Special Achievement",
  xpAmount: 75
)
```

### Method 4: Using ActivityEvent (With Metadata)
```swift
let event = ActivityEvent(
  appName: "Writing",
  activityName: "Essay Completed",
  xpAmount: 100,
  metadata: ["wordCount": 500, "duration": 1800]
)
event.publish()
```

## Adding New Activity Types

Edit `LevelService+Activities.swift`:

```swift
enum ActivityType: String {
  // Existing...
  case newActivity = "New Activity Description"
  
  var xpReward: Int {
    switch self {
    // Existing...
    case .newActivity: return 60
    }
  }
  
  var appName: String {
    switch self {
    // Existing...
    case .newActivity: return "New App"
    }
  }
}
```

## Accessing Statistics

### Get Stats for Specific App
```swift
let stats = LevelService.shared.getStats(for: "Pomodoro")
for stat in stats {
  print("\(stat.activityType): \(stat.count) times, \(stat.totalXPEarned) XP")
}
```

### Get All Stats
```swift
let allStats = LevelService.shared.getAllStats()
```

## Adding Custom Rewards

### Define Rewards
Edit `LevelService+Rewards.swift`:

```swift
static let defaultRewards: [RewardType: Int] = [
  .badge("Achievement Name"): 15,
  .feature("New Feature"): 20,
  .customization("Theme Pack"): 10,
  .milestone("1000 Tasks Done"): 30
]
```

### Check if Reward is Unlocked
```swift
let isUnlocked = LevelService.shared.isRewardUnlocked(.badge("Early Adopter"))
```

### Get All Rewards at Level
```swift
let rewards = LevelService.shared.checkForNewRewards(at: 10)
```

## Creating Stages/Milestones

Stages are automatically handled through the reward system. To add custom logic for stages:

```swift
extension LevelService {
  var currentStage: String {
    guard let progress = currentProgress else { return "Beginner" }
    
    switch progress.currentLevel {
    case 1..<5: return "Novice"
    case 5..<10: return "Apprentice"
    case 10..<20: return "Expert"
    case 20..<50: return "Master"
    default: return "Legend"
    }
  }
}
```

## Future Extensibility

### Adding New Data Models
1. Create model in `Shared/Models/`
2. Add to schema in `LevelService.init()` and `ModelContainerProvider`
3. Create service extension in `Services/LevelService+YourFeature.swift`

### XP Formula Customization
Modify `LevelProgress.xpForLevel()` for different progression curves:

```swift
static func xpForLevel(_ level: Int) -> Int {
  // Linear: level * 100
  // Exponential: Int(pow(Double(level), 1.5) * 50)
  // Custom curve: your formula here
  return level * 100
}
```

### Dynamic Rewards
Rewards can be loaded from backend or computed dynamically:

```swift
func fetchDynamicRewards() async {
  // Fetch from Supabase or compute based on user behavior
}
```

## Example: Complete Integration

```swift
class PomodoroViewModel: ObservableObject, LevelSystemIntegration {
  var appName: String { "Pomodoro" }
  
  func completePomodoro() {
    // Standard way
    LevelService.shared.awardXP(for: .pomodoroCompleted)
    
    // Or with protocol
    publishActivity(name: "Pomodoro Completed", xpAmount: 100)
    
    // Or with event
    ActivityEvent(
      appName: appName,
      activityName: "Focus Session",
      xpAmount: 100,
      metadata: ["duration": 1500]
    ).publish()
  }
}
```

## Best Practices

1. **Use predefined activities** when possible for consistency
2. **Record meaningful activities** - not every interaction needs XP
3. **Balance XP amounts** - keep rewards proportional to effort
4. **Track stats** - use `recordActivity()` for analytics
5. **Test rewards** - use debug view to verify unlock logic
6. **Document activities** - add new cases to this guide

## Statistics & Analytics

The system automatically tracks:
- Activity count per app
- Total XP earned per activity type
- First and last activity timestamps
- App-specific usage patterns

Access these for:
- User insights
- Engagement metrics
- Feature popularity
- Research data collection
