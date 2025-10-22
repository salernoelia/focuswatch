import SwiftUI

struct CalendarEventFormView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var vm: CalendarViewModel
  @StateObject private var appsManager = AppsManager.shared
  private let editingEvent: Event?
  private let defaultDate: Date?

  @State private var title = ""
  @State private var date: Date
  @State private var startTime: Date
  @State private var endTime: Date
  @State private var repeatRule: RepeatRule = .none
  @State private var customWeekdays: [Int] = []
  @State private var selectedAppIndex: Int?
  @State private var reminders: [Reminder] = []
  @State private var editingReminder: Reminder?
  @State private var showingReminderForm = false

  init(
    vm: CalendarViewModel,
    defaultDate: Date? = nil,
    editingEvent: Event? = nil
  ) {
    self.vm = vm
    self.defaultDate = defaultDate
    self.editingEvent = editingEvent

    if let event = editingEvent {
      _ = event.date
      _title = State(initialValue: event.title)
      _date = State(initialValue: event.date)
      _startTime = State(initialValue: event.startTime)
      _endTime = State(initialValue: event.endTime)
      _repeatRule = State(initialValue: event.repeatRule)
      _customWeekdays = State(initialValue: event.customWeekdays)
      _selectedAppIndex = State(initialValue: event.appIndex)
      _reminders = State(initialValue: event.reminders)
    } else {
      let base = defaultDate ?? Date()
      let defaultEnd =
        Calendar.current.date(byAdding: .hour, value: 1, to: base)
        ?? Date().addingTimeInterval(3600)
      _date = State(initialValue: base)
      _startTime = State(initialValue: base)
      _endTime = State(initialValue: defaultEnd)
      _reminders = State(initialValue: [Reminder(minutesBefore: 0, shouldLaunchApp: false)])
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Event") {
          TextField("Title", text: $title)

          Picker("Launch App", selection: $selectedAppIndex) {
            Text("None").tag(nil as Int?)
            ForEach(appsManager.apps, id: \.index) { app in
              Text(app.title).tag(app.index as Int?)
            }
          }
        }

        Section("When") {
          DatePicker(
            "Date",
            selection: $date,
            displayedComponents: .date
          )
          DatePicker(
            "Start",
            selection: $startTime,
            displayedComponents: .hourAndMinute
          )
          DatePicker(
            "End",
            selection: $endTime,
            displayedComponents: .hourAndMinute
          )
        }

        Section("Repeat") {
          Picker("Repeat", selection: $repeatRule) {
            ForEach(RepeatRule.allCases) {
              Text($0.rawValue.capitalized).tag($0)
            }
          }
          if repeatRule == .custom {
            HStack {
              ForEach(1...7, id: \.self) { day in
                let symbol = Calendar.current
                  .veryShortWeekdaySymbols[(day - 1) % 7]
                Button(symbol) {
                  if customWeekdays.contains(day) {
                    customWeekdays.removeAll {
                      $0 == day
                    }
                  } else {
                    customWeekdays.append(day)
                  }
                }
                .foregroundColor(
                  customWeekdays.contains(day)
                    ? .accentColor : .primary
                )
              }
            }
          }
        }

        Section {
          if reminders.isEmpty {
            Text("No reminders")
              .foregroundStyle(.secondary)
          } else {
            ForEach(reminders) { reminder in
              Button {
                editingReminder = reminder
                showingReminderForm = true
              } label: {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text(
                      reminder.minutesBefore == 0
                        ? "At event time"
                        : "\(reminder.minutesBefore) min before"
                    )
                    .font(.body)
                    .foregroundColor(.primary)
                    if let message = reminder.message,
                      !message.isEmpty
                    {
                      Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if reminder.shouldLaunchApp {
                      Text("Launches app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                  }
                  Spacer()
                }
              }
              .swipeActions(
                edge: .trailing,
                allowsFullSwipe: true
              ) {
                Button(role: .destructive) {
                  reminders.removeAll { $0.id == reminder.id }
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
            }
          }

          Menu {
            Button("At event time") {
              editingReminder = Reminder(
                minutesBefore: 0,
                shouldLaunchApp: selectedAppIndex != nil
              )
              showingReminderForm = true
            }
            ForEach([5, 10, 15, 30, 60], id: \.self) { minutes in
              Button("\(minutes) minutes before") {
                editingReminder = Reminder(
                  minutesBefore: minutes,
                  shouldLaunchApp: selectedAppIndex != nil
                )
                showingReminderForm = true
              }
            }
          } label: {
            Label("Add Reminder", systemImage: "bell.badge.fill")
          }
        } header: {
          Text("Reminders")
        }
      }
      .navigationTitle(editingEvent == nil ? "New Event" : "Edit Event")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let combinedStartTime = combineDateTime(
              date: date,
              time: startTime
            )
            let combinedEndTime = combineDateTime(
              date: date,
              time: endTime
            )

            if let editingEvent = editingEvent {
              vm.update(
                eventId: editingEvent.sourceEventId
                  ?? editingEvent.id,
                title: title,
                date: date,
                startTime: combinedStartTime,
                endTime: combinedEndTime,
                repeatRule: repeatRule,
                customWeekdays: customWeekdays,
                appIndex: selectedAppIndex,
                reminders: reminders
              )
            } else {
              let ev = Event(
                title: title,
                date: date,
                startTime: combinedStartTime,
                endTime: combinedEndTime,
                repeatRule: repeatRule,
                customWeekdays: customWeekdays,
                appIndex: selectedAppIndex,
                reminders: reminders
              )
              vm.add(ev)
            }
            dismiss()
          }
          .disabled(title.isEmpty)
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .sheet(isPresented: $showingReminderForm) {
        if let reminder = editingReminder {
          ReminderFormView(
            reminder: reminder,
            onSave: { updatedReminder in
              if let index = reminders.firstIndex(where: {
                $0.id == reminder.id
              }) {
                reminders[index] = updatedReminder
              } else {
                reminders.append(updatedReminder)
              }
              showingReminderForm = false
              editingReminder = nil
            },
            onCancel: {
              showingReminderForm = false
              editingReminder = nil
            }
          )
        }
      }
    }
  }
}

private func combineDateTime(date: Date, time: Date) -> Date {
  let calendar = Calendar.current
  let dateComponents = calendar.dateComponents(
    [.year, .month, .day],
    from: date
  )
  let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

  var combined = DateComponents()
  combined.year = dateComponents.year
  combined.month = dateComponents.month
  combined.day = dateComponents.day
  combined.hour = timeComponents.hour
  combined.minute = timeComponents.minute

  return calendar.date(from: combined) ?? date
}

struct ReminderFormView: View {
  let reminder: Reminder
  let onSave: (Reminder) -> Void
  let onCancel: () -> Void

  @State private var minutesBefore: Int
  @State private var shouldLaunchApp: Bool
  @State private var message: String

  init(
    reminder: Reminder,
    onSave: @escaping (Reminder) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.reminder = reminder
    self.onSave = onSave
    self.onCancel = onCancel
    _minutesBefore = State(initialValue: reminder.minutesBefore)
    _shouldLaunchApp = State(initialValue: reminder.shouldLaunchApp)
    _message = State(initialValue: reminder.message ?? "")
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Timing") {
          Picker("Time", selection: $minutesBefore) {
            Text("At event time").tag(0)
            Text("5 minutes before").tag(5)
            Text("10 minutes before").tag(10)
            Text("15 minutes before").tag(15)
            Text("30 minutes before").tag(30)
            Text("1 hour before").tag(60)
          }
        }

        Section("Actions") {
          Toggle("Launch App", isOn: $shouldLaunchApp)
        }

        Section("Message") {
          TextField(
            "Notification message (optional)",
            text: $message,
            axis: .vertical
          )
          .lineLimit(3...6)
        }
      }
      .navigationTitle("Reminder")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let updatedReminder = Reminder(
              id: reminder.id,
              minutesBefore: minutesBefore,
              shouldLaunchApp: shouldLaunchApp,
              message: message.isEmpty ? nil : message
            )
            onSave(updatedReminder)
          }
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel()
          }
        }
      }
    }
  }
}
