import SwiftData
import SwiftUI

struct CalendarView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var vm: CalendarViewModel?
  @State private var showingForm = false
  @State private var selectedDate: Date = Date()
  @State private var editingEvent: Event?
  @State private var isCalendarCollapsed = false
  @State private var events: [Event] = []

  private func loadEvents() {
    guard let vm = vm else { return }
    events = vm.events(on: selectedDate)
      .sorted { $0.startTime < $1.startTime }
  }

  private var selectedDateString: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "de_DE")
    formatter.dateFormat = "EEE, dd.MM.yyyy"
    return formatter.string(from: selectedDate)
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        calendarSection
        eventsList
      }
      .navigationTitle(selectedDateString)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Add Entry") {
            editingEvent = nil
            showingForm = true
          }
        }
      }
      .sheet(item: $editingEvent) { event in
        if let vm = vm {
          CalendarEventFormView(vm: vm, defaultDate: selectedDate, editingEvent: event)
        }
      }
      .sheet(isPresented: $showingForm) {
        if let vm = vm, editingEvent == nil {
          CalendarEventFormView(vm: vm, defaultDate: selectedDate, editingEvent: nil)
        }
      }
      .onChange(of: showingForm, initial: false) { _, new in
        if !new {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadEvents()
          }
        }
      }
      .onChange(of: editingEvent, initial: false) { _, new in
        if new == nil {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadEvents()
          }
        }
      }
      .onChange(of: selectedDate, initial: false) { _, _ in
        loadEvents()
      }
      .onAppear {
        if vm == nil {
          vm = CalendarViewModel(modelContext: modelContext)
        }
        loadEvents()
      }
    }
  }

  private var calendarSection: some View {
    VStack(spacing: 0) {
      Button {
        withAnimation(.easeInOut(duration: 0.3)) {
          isCalendarCollapsed.toggle()
        }
      } label: {
        HStack {
          Text("Kalender")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
          Spacer()
          Image(systemName: isCalendarCollapsed ? "chevron.down" : "chevron.up")
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
      }

      if !isCalendarCollapsed {
        DatePicker(
          "",
          selection: $selectedDate,
          displayedComponents: [.date]
        )
        .datePickerStyle(GraphicalDatePickerStyle())
        .padding(.horizontal)
      }
    }
  }

  private var eventsList: some View {
    List {
      if events.isEmpty {
        Text("No events scheduled")
          .foregroundColor(.secondary)
          .font(.subheadline)
      } else {
        ForEach(events, id: \.id) { event in
          eventRow(event)
        }
      }
    }
    .listStyle(.insetGrouped)
  }

  private func eventRow(_ event: Event) -> some View {
    Button {
      editingEvent = event
    } label: {
      CalendarEventRowView(event: event)
    }
    .contextMenu {
      Button {
        editingEvent = event
      } label: {
        Label("Edit", systemImage: "pencil")
      }

      Button(role: .destructive) {
        vm?.delete(event)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          loadEvents()
        }
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
    .swipeActions(edge: .trailing) {
      Button(role: .destructive) {
        vm?.delete(event)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          loadEvents()
        }
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

#Preview {
  CalendarView()
    .modelContainer(for: Event.self, inMemory: true)
}
