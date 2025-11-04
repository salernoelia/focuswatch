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
          Text("Current XP")
          Spacer()
          Text("\(viewModel.currentXP)")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("Total XP")
          Spacer()
          Text("\(levelService.currentProgress?.totalXP ?? 0)")
            .foregroundStyle(.secondary)
        }
      }

      Section("Add XP") {
        Button("+ 10 XP") {
          levelService.addXP(10, reason: "Debug test")
        }

        Button("+ 50 XP") {
          levelService.addXP(50, reason: "Debug test")
        }

        Button("+ 100 XP") {
          levelService.addXP(100, reason: "Debug test")
        }

        Button("+ 500 XP") {
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
