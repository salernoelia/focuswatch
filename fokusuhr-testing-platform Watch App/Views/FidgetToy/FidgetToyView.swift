import SwiftUI

struct FidgetToyView: View {
  @StateObject private var viewModel = FidgetToyViewModel()

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
  }
}

#Preview {
  FidgetToyView()
}
