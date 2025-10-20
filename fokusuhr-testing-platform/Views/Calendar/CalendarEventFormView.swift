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

  init(vm: CalendarViewModel, defaultDate: Date? = nil, editingEvent: Event? = nil) {
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
    }
  }

  var body: some View {
    NavigationView {
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
          DatePicker("Date", selection: $date, displayedComponents: .date)
          DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
          DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
        }

        Section("Repeat") {
          Picker("Rule", selection: $repeatRule) {
            ForEach(RepeatRule.allCases) {
              Text($0.rawValue.capitalized).tag($0)
            }
          }
          if repeatRule == .custom {
            HStack {
              ForEach(1...7, id: \.self) { day in
                let symbol = Calendar.current.veryShortWeekdaySymbols[(day - 1) % 7]
                Button(symbol) {
                  if customWeekdays.contains(day) {
                    customWeekdays.removeAll { $0 == day }
                  } else {
                    customWeekdays.append(day)
                  }
                }
                .foregroundColor(customWeekdays.contains(day) ? .accentColor : .primary)
              }
            }
          }
        }

        Section {
          ForEach(reminders) { reminder in
            HStack {
              Text("\(reminder.minutesBefore) min before")
              Spacer()
              Toggle(
                "Launch app",
                isOn: Binding(
                  get: { reminder.shouldLaunchApp },
                  set: { newValue in
                    if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                      reminders[index] = Reminder(
                        id: reminder.id,
                        minutesBefore: reminder.minutesBefore,
                        shouldLaunchApp: newValue
                      )
                    }
                  }
                ))
              Button {
                reminders.removeAll { $0.id == reminder.id }
              } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
            }
          }

          Menu {
            ForEach([5, 10, 15, 30, 60], id: \.self) { minutes in
              Button("\(minutes) minutes before") {
                reminders.append(
                  Reminder(minutesBefore: minutes, shouldLaunchApp: selectedAppIndex != nil))
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
            let combinedStartTime = combineDateTime(date: date, time: startTime)
            let combinedEndTime = combineDateTime(date: date, time: endTime)

            if let editingEvent = editingEvent {
              vm.update(
                eventId: editingEvent.id,
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
    }
  }

  private func combineDateTime(date: Date, time: Date) -> Date {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

    var combined = DateComponents()
    combined.year = dateComponents.year
    combined.month = dateComponents.month
    combined.day = dateComponents.day
    combined.hour = timeComponents.hour
    combined.minute = timeComponents.minute

    return calendar.date(from: combined) ?? date
  }
}
