## Vibration Manager

```swift
// Single vibrations
VibrationManager.shared.lightVibration()
VibrationManager.shared.mediumVibration()
VibrationManager.shared.strongVibration()

// Custom haptic types
VibrationManager.shared.customVibration(.directionDown)

// Progressive vibrations (for other spinning/moving elements)
VibrationManager.shared.startProgressiveVibration(velocity: 25)
VibrationManager.shared.stopProgressiveVibration()
```
