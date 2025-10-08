# Fokusuhr Platform

Repository contains the main development branch for the Fokusuhr Platform, a iOS and watchOS application for assisting kids with focussing on their tasks and helps build
routines intrinsically.

## Class Reference

#### Vibration Manager

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
