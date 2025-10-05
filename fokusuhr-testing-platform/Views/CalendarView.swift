import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var vm: CalendarViewModel
    @State private var showingForm = false
    @State private var selectedDate: Date = Date()
    @State private var editingEvent: CalendarEventModel?
    @State private var isCalendarCollapsed = false

    private var eventsForSelectedDate: [CalendarEventModel] {
        vm.events(on: selectedDate)
          .sorted { $0.startTime < $1.startTime }
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                VStack(spacing: 0) {
                
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isCalendarCollapsed.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Calendar")
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
                

                
                List {
        
                    if eventsForSelectedDate.isEmpty {
                        Text("No events scheduled")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(eventsForSelectedDate) { event in
                            CalendarEventRowView(event: event)
                                .contextMenu {
                                    Button {
                                        editingEvent = event
                                        showingForm = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        withAnimation {
                                            vm.delete(event)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            vm.delete(event)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        editingEvent = event
                                        showingForm = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle(selectedDateString)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingEvent = nil
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm, onDismiss: {
                editingEvent = nil
            }) {
                CalendarEventFormView(vm: vm, defaultDate: selectedDate, editingEvent: editingEvent)
            }
        }
    }
}


#Preview {
    CalendarView()
}
