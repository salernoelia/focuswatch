import SwiftUI

struct FidgetToyView: View {
  @StateObject private var viewModel = FidgetToyViewModel()
  private let appLogger = AppLogger.shared

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
      Circle()
        .fill(Color.gray)
        .frame(width: 56, height: 56)
        .offset(viewModel.position)
        .gesture(
          DragGesture()
            .onChanged { value in
              viewModel.updatePosition(value)
            }
            .onEnded { _ in
              viewModel.endDrag()
            }
        )
        .animation(.spring(), value: viewModel.position)
    }
    .onAppear {
      appLogger.logViewLifecycle(appName: "fidget", event: "open")
    }
    .onDisappear {
      appLogger.logViewLifecycle(appName: "fidget", event: "close")
    }
  }
}

#Preview {
  FidgetToyView()
}
