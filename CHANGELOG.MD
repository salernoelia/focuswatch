# Releases

## [1.2.8] - 16.03.2026
- Fixed vibration intensity not being applied and inconsistencies when triggered (ISSUE-215)
- 

## [1.2.7] - 09.03.2026
- Improved notification scheduling (still work in progress...)
- Holding breath configuration option in color breathing
- Fix: Pomodoro timer resetting when watch in standby
- ⁠Fix: Jittery animation of the Color Breathing animation

## [1.2.6] - 12.02.2026
- Added checklist swipe direction mapping (configurable collect/delay left/right) configurable "Companion App > Checklists > Gear Icon (Settings)"
- Added checklist reset/cooldown configuration (daily/weekly/none), configurable within "Companion App > Checklists"
- Improved checklist onboarding (tutorial) where user has to swipe in the correct direction for both "collect" and "delay"
- Checklist items turn green in the bottom bar when collected for better progression feedback
- Added undo button after accidental swipe (visible for 2s)
- Navigation tabs of watch order changed -> Checklists, Tools, Calendar, Level, Settings

## [1.2.5] - 02.02.2026
- Enhanced sync reliability for calendar events trough "high priority notification" calls
- Improved pomodoro session timer accuracy

## [1.2.4] - 19.12.2025
- Fixed color breathing app out of sync & broken counter
- Fixed multiple localization issues & enhanced ux writing

## [1.2.3] - 18.12.2025
- Fixed fidget vibration issue when leaving the app
- Added force sync of checklists on pull down of the "Checklists" page on iPhone
- Enabled checklist item reordering via long-press and drag
- Redesigned checklist editor interface on iPhone
- Added batch-adding of items from Photos for Checklist items
- More solid sync system for checklist data between Phone and Watch
- Hashing of checklist data to prevent duplicate items -> eventual breaking change for existing checklists, worst case delete one (by sliding the checklist to the left) and re-create it

## [1.2.2] - 07.12.2025

- All "FocusPoints" are now called "Points" throughout the app as it was just too long for many UI elements
- Minor UI and translation improvements
- Added new Sync system for improved reliability between Phone and Watch
- Fix that the Watch-ID does not get displayed in the Complication

## [1.2.1] - 01.12.2025

#### Changes
- Micro-apps configuration options from the Wizard
- Rename "XP" to "Points"
- Level Up "Current Level * 100" amount of Focus Points
- The Focus Meter wheel is now not red->orange->green anymore but instead orange->green<-orange
- Improved Phone and Watch connection stability and many background synchronisation capabilities
- Added missing translations for DE

