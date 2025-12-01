import SwiftUI

struct LevelDebugView: View {
  @StateObject private var viewModel = LevelViewModel.shared
  private let levelService = LevelService.shared

  var body: some View {
    List {
      Section("Current Progress") {
        HStack {
          Text("Level")
          Spacer()
          Text("\(viewModel.currentLevel)")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("Current FocusPoints")
          Spacer()
          Text("\(viewModel.currentXP)")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("Total FocusPoints")
          Spacer()
          Text("\(levelService.currentProgress?.totalXP ?? 0)")
            .foregroundStyle(.secondary)
        }
      }

      Section("Add FocusPoints") {
        Button("+ 10 FocusPoints") {
          levelService.addXP(10, reason: "Debug test")
        }

        Button("+ 50 FocusPoints") {
          levelService.addXP(50, reason: "Debug test")
        }

        Button("+ 100 FocusPoints") {
          levelService.addXP(100, reason: "Debug test")
        }

        Button("+ 500 FocusPoints") {
          levelService.addXP(500, reason: "Debug test")
        }
      }

      Section("Actions") {
        Button("Reset Progress", role: .destructive) {
          levelService.resetProgress()
        }
      }
    }
    .navigationTitle("Level Debug")
  }
}

#Preview {
  LevelDebugView()
}
