This masterplan outlines the transformation of the `WatchConnector` from a monolithic "God Object" into a modular, service-oriented connectivity layer.

## 1. Executive Summary

The current `WatchConnector` architecture is fragile and difficult to scale. It violates the Single Responsibility Principle by mixing transport logic (`WCSession` management) with business logic (Calendar parsing, Image encoding, Level logic). Furthermore, the data serialization strategy (JSON → Data → Base64 String → Dictionary) introduces unnecessary CPU and memory overhead.

**The Goal:** Refactor the connectivity layer into a clean **Transport -> Router -> Service** architecture.

---

## 2. Code Quality Assessment

### A. The "God Object" Anti-Pattern

- **Problem:** `WatchConnector.swift` (and its extensions) is the central dependency for almost every ViewModel.
- **Evidence:** `WatchConnector` holds specific state variables like `checklistData`, `lastCalendarSyncHash`, and `checklistManager`.
- **Risk:** Modifying the Calendar sync logic requires recompiling the entire Connector. A crash in image encoding for Checklists brings down the entire connectivity layer.

### B. Inefficient Serialization

- **Problem:** Data is encoded three times before transmission.
- **Evidence:** `WatchConnectorCalendar.swift`: `data.base64EncodedString()`.
- **Impact:** `WCSession` natively supports `Data` objects. Converting `Data` to Base64 adds ~33% overhead to payload size and wastes CPU cycles on encoding/decoding, which is critical on the Watch's limited battery/processor.

### C. Tight Coupling

- **Problem:** ViewModels depend directly on the specific implementation of `WatchConnector`.
- **Evidence:** `CalendarViewModel.swift` calls `watchConnector.syncCalendarToWatch()`.
- **Impact:** This makes unit testing ViewModels difficult without mocking the entire `WCSession` stack.

### D. Hardcoded Keys

- **Problem:** String literals are used for routing.
- **Evidence:** Keys like `"calendarData"`, `"updateChecklist"`, `"forceOverwrite"` are scattered across files.
- **Risk:** High probability of typos causing silent sync failures.

---

## 3. The New Architecture: Transport-Router-Service

We will move to a three-tier architecture:

1.  **Transport Layer (`ConnectivityTransport`):** Wraps `WCSession`. Handles activation, reachability, and raw byte transmission. It knows _nothing_ about app features.
2.  **Routing Layer (`SyncRouter`):** Decodes incoming raw headers and dispatches payloads to the correct service.
3.  **Service Layer (`FeatureSyncService`):** Feature-specific classes (e.g., `CalendarSyncService`) that handle business logic, diffing, and Model conversion.

---

## 4. Execution Roadmap

### Phase 1: Foundation (The Transport Layer)

**Action:** Create a generic wrapper around `WCSession` and a strict Data Protocol.

1.  **Define the Protocol:**
    Create a `Shared/Connectivity/SyncPayload.swift`.

    ```swift
    enum SyncMessageType: String, Codable {
        case calendar, checklist, level, config, auth, telemetry, command
    }

    struct SyncPacket: Codable {
        let type: SyncMessageType
        let payload: Data // Raw JSON data of the specific model
        let timestamp: Date
        let metadata: [String: String]? // For things like "forceOverwrite"
    }
    ```

2.  **Create `ConnectivityTransport`:**
    - **Replace:** `Services/WatchConnectorConnectivity.swift`
    - **Responsibility:**
      - Manage `WCSession` activation and delegation.
      - Expose `send(packet: SyncPacket)` method.
      - Expose a Combine Subject `packetReceived` that emits `SyncPacket`.
    - **Rule:** No Base64 encoding. Use `WCSession.sendMessageData` or `updateApplicationContext(["packet": encodedPacket])`.

### Phase 2: Modularization (The Services)

**Action:** Extract logic from the `WatchConnector` extensions into standalone services.

1.  **Calendar Sync Service:**

    - **Source:** `Services/WatchConnectorCalendar.swift`
    - **New Class:** `CalendarSyncService`
    - **Logic:**
      - Accepts `[Event]`.
      - Performs the Hashing/Diffing logic (`computeCalendarHash`).
      - Encodes to `Data`.
      - Calls `ConnectivityTransport.send(.calendar, data)`.
    - **Refactor:** Remove direct `SwiftData` context access. The Service should receive plain objects (DTOs) from the ViewModel or a DataProvider.

2.  **Checklist Sync Service:**

    - **Source:** `Services/WatchConnectorData.swift`
    - **New Class:** `ChecklistSyncService`
    - **Logic:**
      - Handles `ChecklistData`.
      - **Crucial Fix:** Isolate the Image encoding logic (currently in `syncChecklistToWatch`) into a background actor/queue within this service to prevent UI freezing.

3.  **Level & Config Services:**
    - **Source:** `WatchConnectorLevel.swift`, `WatchConnectorConfigurations.swift`
    - **New Classes:** `LevelSyncService`, `ConfigSyncService`.

### Phase 3: The Router (The Glue)

**Action:** Create the dispatcher that sits between Transport and Services.

1.  **Create `SyncCoordinator` (Singleton):**
    - Initializes `ConnectivityTransport`.
    - Holds references to `CalendarSyncService`, `ChecklistSyncService`, etc.
    - **Inbound Logic:** Subscribes to `ConnectivityTransport.packetReceived`. Switches on `packet.type` and calls `calendarService.handleInbound(packet.payload)`.

### Phase 4: Integration & Cleanup

**Action:** Update ViewModels to use Services instead of the Connector.

1.  **Update `CalendarViewModel`:**

    - Inject `CalendarSyncService`.
    - Replace `watchConnector.syncCalendarToWatch()` with `calendarSyncService.sync(events)`.

2.  **Update `ChecklistViewModel`:**

    - Remove `watchConnector.checklistData = data`.
    - The ViewModel manages the source of truth. It pushes updates to `ChecklistSyncService`.

3.  **Watch App Mirroring:**

    - Apply the same `Transport -> Router -> Service` pattern to the Watch App.
    - `WatchApp.swift` should initialize the `SyncCoordinator` on launch.

4.  **Delete Legacy Files:**
    - Remove `WatchConnector.swift` and all its extensions (`WatchConnectorCalendar.swift`, etc.).

---

## 5. Specific Refactoring Rules

1.  **No Base64:** All data transmission must use raw `Data` via `WCSession`.
2.  **No "God" State:** The `ConnectivityTransport` must be stateless regarding business data. It does not store `checklistData` or `events`.
3.  **Explicit DTOs:** Use `EventTransfer` (already exists) and similar DTOs for all transfers. Do not send internal App State objects directly if they contain local-only properties.
4.  **Error Handling:** Replace `print` statements with a unified `ErrorLogger` (already present) but ensure errors are propagated back to the UI via the specific Service, not a generic `lastError` on the Connector.

## 6. Directory Structure Target

```text
/Shared
  /Connectivity
    SyncPacket.swift (The Protocol)
    ConnectivityTransport.swift (The WCSession Wrapper)
    SyncCoordinator.swift (The Router)

/Services (iOS & Watch)
  /Sync
    CalendarSyncService.swift
    ChecklistSyncService.swift
    LevelSyncService.swift
    ConfigSyncService.swift
```

## 7. Quickest Wins

If a full rewrite is not immediately possible, perform these **Redos** on the current code:

1.  **Fix Base64:** Modify `WatchConnectorCalendar.swift` and `WatchConnectorData.swift` to stop using `.base64EncodedString()`. Pass the `Data` object directly into the dictionary.
2.  **Extract Image Logic:** Move the image file reading and encoding loop in `WatchConnectorData.swift` (lines 66-93) to a background queue (`DispatchQueue.global(qos: .utility)`).
3.  **Consolidate Constants:** Move all hardcoded strings (`"calendarData"`, `"updateChecklist"`) into a `SyncConstants` struct to prevent typos.
