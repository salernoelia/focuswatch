---
applyTo: "**"
---

- Point out bad patterns before continuing
- No code comments
- No hallucination, work professionally
- Do not break existing functionality
- Do not check linting errors
- Do not edit entitlements or Info.plist, manage these in Xcode
- iOS (16+) companion app and watchOS (10+) project
- Shared data for constants, errors, models, services, utils
- Use only Supabase backend via `/Shared/Utils/Supabase.swift` and auto-generated `Schema.swift`
- Prefer SwiftData for future migration, else use UserDefaults
- Use MVC inside each view's directory
- Share data between iOS and watchOS via "WatchConnector.." in Services
- Prioritize simplicity, robustness, and minimalism
- Always use Localization for strings, default English
- Watch uses static UUID "uuid" in UserDefaults and `Shared/Configs/WatchConfig.swift` (WatchConfig.shared.uuid)
- Logging via `/Shared/Services/TelemetryManager.swift`, toggle in `SettingsViewModel.swift` (iOS)
- Use clean, minimal SwiftUI, no emojis, symbols only if beneficial, prefer Localized text
- Ask apple-docs mcp for API documentation
- if you do edits, check if something exists already, and if you delete something cleanup after yourself

```
.
├── Development.xcconfig
├── docs
│   ├── documentation__WatchConnectivity__WCSession.json
│   ├── LEVEL_SYSTEM_INTEGRATION.md
│   ├── LEVEL_SYSTEM_SUMMARY.md
│   ├── LEVEL_SYSTEM.md
│   ├── SwiftData.json
│   ├── technologies.json
│   └── WatchConnectivity.json
├── Example.xcconfig
├── examples
│   └── logging_format.json
├── fokusuhr-testing-platform
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   ├── 1024.png
│   │   │   ├── AppIcon1024x1024 1.png
│   │   │   ├── AppIcon1024x1024.png
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── CompanionApp.swift
│   ├── CompanionView.swift
│   ├── Constants
│   │   └── CodingKeys.swift
│   ├── fokusuhr-testing-platform.entitlements
│   ├── Info.plist
│   ├── Models
│   │   └── Gallery.swift
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Services
│   │   ├── GalleryStorage.swift
│   │   ├── WatchConnector.swift
│   │   ├── WatchConnectorCalendar.swift
│   │   ├── WatchConnectorCommands.swift
│   │   ├── WatchConnectorConnectivity.swift
│   │   ├── WatchConnectorData.swift
│   │   ├── WatchConnectorLevel.swift
│   │   └── WatchConnectorMessages.swift
│   ├── Utils
│   │   └── PhotoPicker.swift
│   └── Views
│       ├── Auth
│       │   ├── AuthManager.swift
│       │   ├── LoginRequiredView.swift
│       │   └── LoginView.swift
│       ├── Calendar
│       │   ├── CalendarEventFormView.swift
│       │   ├── CalendarEventRowView.swift
│       │   ├── CalendarView.swift
│       │   └── CalendarViewModel.swift
│       ├── Checklist
│       │   ├── ChecklistAddItemView.swift
│       │   ├── ChecklistDetailView.swift
│       │   ├── ChecklistEditorView.swift
│       │   ├── ChecklistItemEditRow.swift
│       │   └── ChecklistViewModel.swift
│       ├── Feedback
│       │   ├── FeedbackManager.swift
│       │   └── FeedbackView.swift
│       ├── Gallery
│       │   ├── GalleryItemCard.swift
│       │   └── GalleryView.swift
│       ├── Journal
│       │   ├── JournalContentView.swift
│       │   ├── JournalHistoryEntryRow.swift
│       │   ├── JournalHistoryView.swift
│       │   ├── JournalManager.swift
│       │   └── JournalView.swift
│       ├── Level
│       │   ├── LevelView.swift
│       │   └── MilestoneEditView.swift
│       ├── Onboarding
│       │   └── OnboardingView.swift
│       ├── Settings
│       │   ├── SettingsView.swift
│       │   └── SettingsViewModel.swift
│       ├── Testuser
│       │   ├── UserAddView.swift
│       │   ├── UserRow.swift
│       │   └── UserSelectionView.swift
│       └── Wizard
│           └── WizardView.swift
├── fokusuhr-testing-platform Watch App
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   ├── 1024.png
│   │   │   └── Contents.json
│   │   ├── Backblech.imageset
│   │   │   ├── Backblech.png
│   │   │   └── Contents.json
│   │   ├── Backpapier.imageset
│   │   │   ├── Backpapier.png
│   │   │   └── Contents.json
│   │   ├── Bleistift.imageset
│   │   │   ├── Bleistift.png
│   │   │   └── Contents.json
│   │   ├── Buntes Papier.imageset
│   │   │   ├── Buntes Papier.png
│   │   │   └── Contents.json
│   │   ├── Contents.json
│   │   ├── Ei.imageset
│   │   │   ├── Contents.json
│   │   │   └── Ei.png
│   │   ├── Haselnüsse.imageset
│   │   │   ├── Contents.json
│   │   │   └── Haselnüsse 1.png
│   │   ├── Kelle.imageset
│   │   │   ├── Contents.json
│   │   │   └── Kelle.png
│   │   ├── Leimstift.imageset
│   │   │   ├── Contents.json
│   │   │   └── Leimstift.png
│   │   ├── Lineal.imageset
│   │   │   ├── Contents.json
│   │   │   └── Lineal.png
│   │   ├── Locher.imageset
│   │   │   ├── Contents.json
│   │   │   └── Locher.png
│   │   ├── Maizena.imageset
│   │   │   ├── Contents.json
│   │   │   └── Maizena.png
│   │   ├── Messlöffel.imageset
│   │   │   ├── Contents.json
│   │   │   └── Messlöffel.png
│   │   ├── Schere.imageset
│   │   │   ├── Contents.json
│   │   │   └── Schere.png
│   │   ├── Schokoladenpulver.imageset
│   │   │   ├── Contents.json
│   │   │   └── Schokoladenpulver.png
│   │   ├── Schüssel.imageset
│   │   │   ├── Contents.json
│   │   │   └── Schüssel.png
│   │   ├── Topflappen.imageset
│   │   │   ├── Contents.json
│   │   │   └── Topflappen.png
│   │   ├── Waage.imageset
│   │   │   ├── Contents.json
│   │   │   └── Waage.png
│   │   ├── Wackelaugen.imageset
│   │   │   ├── Contents.json
│   │   │   └── Wackelaugen.png
│   │   ├── Wolle.imageset
│   │   │   ├── Contents.json
│   │   │   └── Wolle.png
│   │   └── Zucker.imageset
│   │       ├── Contents.json
│   │       └── Zucker.png
│   ├── Classifiers
│   │   └── MultiClassifier.mlmodel
│   ├── FokusUhr Watch App.entitlements
│   ├── fokusuhr-testing-platform Watch App.entitlements
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Services
│   │   ├── AppLogger.swift
│   │   ├── AudioRecorder.swift
│   │   ├── AuthManager.swift
│   │   ├── GalleryManager.swift
│   │   ├── VibrationManager.swift
│   │   ├── WatchConnector.swift
│   │   └── WatchConnectorLevel.swift
│   ├── Utils
│   │   ├── ActivityPredictor.swift
│   │   ├── FeatureCalculator.swift
│   │   └── RingBuffer.swift
│   ├── Views
│   │   ├── Anne
│   │   │   └── AnneView.swift
│   │   ├── AppCardView.swift
│   │   ├── Calendar
│   │   │   ├── CalendarEntryTriggerConsent.swift
│   │   │   ├── CalendarView.swift
│   │   │   └── CalendarViewModel.swift
│   │   ├── Checklist
│   │   │   ├── ChecklistCard.swift
│   │   │   ├── ChecklistCompletionView.swift
│   │   │   ├── ChecklistDescriptionView.swift
│   │   │   ├── ChecklistInstructionsView.swift
│   │   │   ├── ChecklistMainView.swift
│   │   │   ├── ChecklistProgressIndicator.swift
│   │   │   ├── ChecklistResumePromptView.swift
│   │   │   ├── ChecklistView.swift
│   │   │   └── ChecklistViewModel.swift
│   │   ├── ColorBreathing
│   │   │   ├── ColorBreathingView.swift
│   │   │   └── ColorBreathingViewModel.swift
│   │   ├── FidgetToy
│   │   │   ├── FidgetToyView.swift
│   │   │   └── FidgetToyViewModel.swift
│   │   ├── Level
│   │   │   ├── LevelDebugView.swift
│   │   │   ├── LevelRewardView.swift
│   │   │   ├── LevelView.swift
│   │   │   └── LevelViewModel.swift
│   │   ├── Pomodoro
│   │   │   ├── PomodoroConfig.swift
│   │   │   ├── PomodoroConfigRow.swift
│   │   │   ├── PomodoroConfigView.swift
│   │   │   ├── PomodoroExtendedRuntimeSessionDelegate.swift
│   │   │   ├── PomodoroPhase.swift
│   │   │   ├── PomodoroTimerView.swift
│   │   │   ├── PomodoroView.swift
│   │   │   └── PomodoroViewModel.swift
│   │   ├── Speedometer
│   │   │   ├── SpeedometerNeedleView.swift
│   │   │   └── SpeedometerView.swift
│   │   └── Writing
│   │       ├── EmaModel.swift
│   │       ├── WritingColorView.swift
│   │       ├── WritingConfigManager.swift
│   │       ├── WritingConfigurationView.swift
│   │       ├── WritingDBManager.swift
│   │       ├── WritingExerciseManager.swift
│   │       ├── WritingHapticFeedbackManager.swift
│   │       ├── WritingLocationManager.swift
│   │       ├── WritingManager.swift
│   │       ├── WritingMotionManager.swift
│   │       ├── WritingTimeManager.swift
│   │       └── WritingView.swift
│   ├── WatchApp.swift
│   └── WatchView.swift
├── fokusuhr-testing-platform-Watch-App-Info.plist
├── fokusuhr-testing-platform.xcodeproj
│   ├── project.pbxproj
│   ├── project.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   │   └── swiftpm
│   │   │       ├── configuration
│   │   │       └── Package.resolved
│   │   └── xcuserdata
│   │       └── eliasalerno.xcuserdatad
│   │           ├── IDEFindNavigatorScopes.plist
│   │           └── UserInterfaceState.xcuserstate
│   ├── xcshareddata
│   │   └── xcschemes
│   │       ├── fokusuhr-testing-platform Watch App.xcscheme
│   │       └── fokusuhr-testing-platform.xcscheme
│   └── xcuserdata
│       └── eliasalerno.xcuserdatad
│           ├── xcdebugger
│           │   └── Breakpoints_v2.xcbkptlist
│           └── xcschemes
│               └── xcschememanagement.plist
├── Production.xcconfig
├── README.md
├── Shared
│   ├── Configs
│   │   ├── SupabaseConfig.swift
│   │   └── WatchConfig.swift
│   ├── Constants
│   │   └── AppConstants.swift
│   ├── Localizable.xcstrings
│   ├── Models
│   │   ├── ActivityStats.swift
│   │   ├── AppInfo.swift
│   │   ├── Calendar.swift
│   │   ├── Checklist.swift
│   │   ├── ChecklistProgress.swift
│   │   ├── LevelMilestone.swift
│   │   ├── LevelProgress.swift
│   │   └── Schema.swift
│   ├── Services
│   │   ├── AppsManager.swift
│   │   ├── LevelService.swift
│   │   ├── LevelService+Activities.swift
│   │   ├── LevelService+Stats.swift
│   │   ├── SupervisorManager.swift
│   │   ├── TelemetryManager.swift
│   │   └── TestUsersManager.swift
│   └── Utils
│       ├── AppError.swift
│       ├── ErrorLogger.swift
│       ├── LevelSystemIntegration.swift
│       ├── ModelContainerProvider.swift
│       ├── Supabase.swift
│       └── ValidationHelper.swift
├── supabase
│   ├── config.toml
│   ├── functions
│   │   ├── invite_supervisor
│   │   │   ├── deno.json
│   │   │   ├── deno.lock
│   │   │   └── index.ts
│   │   └── publishBugToNotionTickets
│   │       ├── deno.json
│   │       └── index.ts
│   ├── migrations
│   │   ├── 20250902224853_init.sql
│   │   ├── 20250903221741_add_rls.sql
│   │   ├── 20250903221928_add_policies.sql
│   │   ├── 20250903222153_user_id_to_test_user_id.sql
│   │   ├── 20250903222613_test_user_table_changes.sql
│   │   ├── 20250904173029_user_id_col_for_supervisors.sql
│   │   ├── 20250904173722_better_intergation_with_auth_uid.sql
│   │   ├── 20250904174106_journals_for_your_own_id_only.sql
│   │   ├── 20250904174538_apps_table.sql
│   │   ├── 20250923195343_apps_table.sql
│   │   ├── 20250923200855_rm_experiences_table.sql
│   │   ├── 20250923200922_add_pgvector.sql
│   │   ├── 20250923201429_add_app_logs_table_and_rls.sql
│   │   ├── 20250923215438_function_automatic_supervisor_creation.sql
│   │   ├── 20250924102830_change_journal_rls.sql
│   │   ├── 20250924103355_return_of_app_name_for_convenience.sql
│   │   ├── 20250924120000_fix_supervisor_trigger.sql
│   │   ├── 20250924120001_add_email_column_to_supervisors.sql
│   │   ├── 20250924120002_fix_supervisor_trigger_with_logging.sql
│   │   ├── 20250928202215_add timestamptz col to journals.sql
│   │   ├── 20251024133238_add_feedback_table.sql
│   │   ├── 20251024134448_add_implemented_bool_to_feedback_table.sql
│   │   ├── 20251024140110_fix_rls_for_inserting_feedback_as_anon.sql
│   │   ├── 20251024141330_fix_rls_updateable.sql
│   │   ├── 20251029112446_add_watch_id.sql
│   │   ├── 20251029124805_remote_schema.sql
│   │   └── 20251029124945_rm_app_id_ref.sql
│   └── seed.sql
├── version-complication
│   ├── AppIntent.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   └── Contents.json
│   │   ├── Contents.json
│   │   └── WidgetBackground.colorset
│   │       └── Contents.json
│   ├── Info.plist
│   ├── widget.swift
│   └── widgetExtension.entitlements
└── watch-notification
    ├── Info.plist
    └── NotificationService.swift
```

- Use the command "tree" in the commandline to see the latest directory tree if you need it
- Never write any code comments OR SUMMARIES, or lists of what you did except you were asked for it, nor ever be verbose unless asked.
- Use apple-doc and supabase mcp server for reference
- Localization main is English
