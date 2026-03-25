import SwiftUI

struct MilestoneEditView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var viewModel: LevelViewModel

  @State private var levelRequired: Int = 5
  @State private var title: String = ""
  @State private var description: String = ""
  @State private var isEnabled: Bool = true

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Stepper("Level \(levelRequired)", value: $levelRequired, in: 1...100)
        }

        Section {
          TextField("Title", text: $title)
          TextField("Description", text: $description, axis: .vertical)
            .lineLimit(2...4)
        }

        Section {
          Toggle("Enabled", isOn: $isEnabled)
        }
      }
      .navigationTitle("New Milestone")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            let milestone = LevelMilestone(
              levelRequired: levelRequired,
              title: title,
              description: description,
              isEnabled: isEnabled
            )
            viewModel.addMilestone(milestone)
            dismiss()
          }
          .disabled(title.isEmpty)
        }
      }
    }
  }
}

struct MilestoneDetailView: View {
  let milestone: LevelMilestone
  @ObservedObject var viewModel: LevelViewModel

  @State private var levelRequired: Int
  @State private var title: String
  @State private var description: String
  @State private var isEnabled: Bool
  @State private var saveTask: Task<Void, Never>?

  init(milestone: LevelMilestone, viewModel: LevelViewModel) {
    self.milestone = milestone
    self.viewModel = viewModel
    _levelRequired = State(initialValue: milestone.levelRequired)
    _title = State(initialValue: milestone.title)
    _description = State(initialValue: milestone.description)
    _isEnabled = State(initialValue: milestone.isEnabled)
  }

  var body: some View {
    Form {
      Section {
        Stepper("Level \(levelRequired)", value: $levelRequired, in: 1...100)
          .onChange(of: levelRequired) { _, _ in
            debouncedSave()
          }
      }

      Section {
        TextField("Title", text: $title)
          .onChange(of: title) { _, _ in
            debouncedSave()
          }

        TextField("Description", text: $description, axis: .vertical)
          .lineLimit(2...4)
          .onChange(of: description) { _, _ in
            debouncedSave()
          }
      }

      Section {
        Toggle("Enabled", isOn: $isEnabled)
          .onChange(of: isEnabled) { _, _ in
            saveChanges()
          }
      }
    }
    .navigationTitle("Milestone")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func debouncedSave() {
    saveTask?.cancel()
    saveTask = Task {
      try? await Task.sleep(nanoseconds: 300_000_000)
      if !Task.isCancelled {
        await MainActor.run {
          saveChanges()
        }
      }
    }
  }

  private func saveChanges() {
    #if DEBUG
      print("💾 Saving milestone changes: \(title)")
    #endif
    let updated = LevelMilestone(
      id: milestone.id,
      levelRequired: levelRequired,
      title: title,
      description: description,
      isEnabled: isEnabled
    )
    viewModel.updateMilestone(updated)
  }
}
