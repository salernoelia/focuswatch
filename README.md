# Fokusuhr Testing Platform

This repository contains prototypes developed during the Fokusuhr workshops. 
It is not production-ready; rather, its purpose is to provide a flexible, testable foundation for TestFlight 
builds that can be quickly adjusted and expanded to evaluate ideas and concepts that are too complex for a simple clickable prototype.

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
