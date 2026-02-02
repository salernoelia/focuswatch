# Architecture & Analysis Report
**Date:** 30-01-2025
**Project:** Fokusuhr Platform (iOS & Watch App)

## 1. Executive Summary
The `fokusuhr-platform` is a sophisticated ecosystem utilizing WatchOS for data collection and iOS for management. The architecture is generally clean but relies on a hybrid persistence strategy (Supabase, SwiftData, UserDefaults, Files) that introduces complexity.

**CRITICAL FINDING:** The Watch App's timer implementation (`WritingTimeManager`) is **not robust**. It relies on a simple second-by-second increment/decrement loop using `Timer`. This will lead to time drift and potential pauses when the application framework suspends execution or during heavy processing, compromising the integrity of the collected data.

## 2. Architecture Analysis

### A. Connectivity (Watch <-> iOS)
- **Implementation:** The `ConnectivityTransport` class wraps `WCSession` effectively as a singleton.
- **Safety:** The critical rule of `WCSession.delegate` being a single point of contact is respected. `GalleryManager` sends messages but does not attempt to usurp the delegate role.
- **Robustness:** The Watch App implements an aggressive reachability check (15s timer). While this ensures liveness, it may impact battery life.
- **Data Flow:**
    - **Context:** Application Context is used for state syncing (Auth, Config).
    - **Messages:** Interactive messages are used for immediate actions (Sync, Acks).
    - **Files:** `WCSessionFileTransfer` is used correctly for images.

### B. Persistence & specific Data Flow
The app uses a "Source of Truth" hierarchy:
1.  **Supabase (Remote):** Canonical data for User, Logs, configuration.
2.  **SwiftData (iOS Local):** Caches `LevelProgress`, `Calendar`, `ActivityStats`.
3.  **UserDefaults (Watch Local):** Stores `LevelMilestones`, `AppConfigurations`, and `FailedUploads`.
4.  **File System:** Stores images and sensor data (`.bin` files).

**Risk:** Synchronization between `SwiftData` (iOS) and `UserDefaults` (Watch) is manual. `SyncCoordinator` handles this via JSON serialization, but schema changes in `SwiftData` models must be manually reflected in the JSON decoding logic on the Watch, creating a maintenance burden.

### C. Session Management
- **State Machine:** `WritingExerciseManager` serves as the central state machine. It correctly handles `WKExtendedRuntimeSession` to enable background operation.
- **Upload Queue:** `DataStorageManager` (in `WritingDBManager.swift`) implements a robust offline queue. Failed uploads are persisted in `UserDefaults` and retried, ensuring no data loss during connectivity dropouts.

## 3. Critical Issues & Bugs

### [CRITICAL] Timer Implementation Flaw
**File:** `WritingTimeManager.swift`
**Severity:** High
**Issue:** The timer logic simply increments/decrements a counter every 1.0 seconds.
```swift
self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { ...
  currentTime -= 1
}
```
**Impact:** `Timer` is not guaranteed to fire exactly on time. If the main thread is busy or the app is suspended (even briefly), ticks will be missed. Over a 25-minute Pomodoro session, this can lead to significant drift.
**Fix:** Store the `startTime` (or `targetEndTime`) and calculate `currentTime` as `targetTime - Date()`.

### [HIGH] Force Unwraps / Fatal Errors
**File:** `WritingDBManager.swift` (and others)
**Severity:** Medium
**Issue:** The app crashes intentionally if the Documents directory is inaccessible.
```swift
fatalError("Unable to access Documents directory")
```
**Impact:** While rare, if the device storage is protected or full, this will cause an immediate crash rather than a graceful error handling.

### [MEDIUM] Aggressive Connectivity Polling
**File:** `ConnectivityTransport.swift` (Watch)
**Severity:** Low
**Issue:** A timer checks connection health every 15 seconds.
**Impact:** Potential battery drain on the Apple Watch. `WCSessionDelegate` callbacks (`sessionReachabilityDidChange`) should be relied upon instead of polling.

## 4. Recommendations
1.  **Refactor Timer:** Rewrite `WritingTimeManager` to use `Date` based calculations for accuracy.
2.  **Harmonize Models:** Consider using a shared Swift package for models to ensure `SwiftData` models on iOS and `Codable` structs on Watch stay in sync.
3.  **Remove Fatal Errors:** Replace `fatalError` with `ErrorLogger.log` and graceful degradation (e.g., disable recording) to prevent crashes.

## 5. Conclusion
The application is well-structured for a prototype/MVP but needs hardening of the core timing logic before being relied upon for precise data collection. The connectivity layer is solid.
