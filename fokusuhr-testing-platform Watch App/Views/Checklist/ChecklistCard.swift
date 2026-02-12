import SwiftUI

struct ChecklistCard<Item: ChecklistItemProtocol>: View {
  let item: Item
  let onCollect: () -> Void
  let onLater: () -> Void

  @State private var dragOffset: CGFloat = 0
  @State private var scale: CGFloat = 1.0
  @State private var opacity: Double = 1.0
  @State private var isProcessing = false
  @State private var cachedImage: UIImage?

  private let dragThreshold: CGFloat = 40
  private let animationDuration: Double = 0.3

  var body: some View {
    VStack(spacing: 16) {
      Text(item.title)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .lineLimit(4)
        .multilineTextAlignment(.center)
        .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 130)
    .background(
      ZStack {
        if let image = cachedImage {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .clipped()
            .brightness(-0.2)
        } else {
          Color.blue.opacity(0.6)
        }
      }

    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(borderColor, lineWidth: strokeWidth)
    )
    .scaleEffect(scale)
    .opacity(opacity)
    .offset(x: dragOffset)
    .disabled(isProcessing)
    .gesture(
      DragGesture(minimumDistance: 5)
        .onChanged(handleDragChange)
        .onEnded(handleDragEnd)
    )
    .onAppear {
      if cachedImage == nil {
        cachedImage = loadImage(named: item.imageName)
      }
    }
  }

  private var borderColor: Color {
    if abs(dragOffset) < 20 { return .clear }
    return dragOffset > 0 ? .green : .yellow
  }

  private var strokeWidth: CGFloat {
    abs(dragOffset) > 20 ? 3 : 0
  }

  private func handleDragChange(_ value: DragGesture.Value) {
    guard !isProcessing else { return }

    let translation = value.translation.width

    if abs(translation) > abs(value.translation.height) {
      dragOffset = translation * 0.8
      let progress = min(abs(translation) / 100, 1.0)
      scale = 1.0 - (progress * 0.05)
    }
  }

  private func handleDragEnd(_ value: DragGesture.Value) {
    guard !isProcessing else { return }

    let translation = value.translation.width
    let velocity = value.velocity.width

    if abs(translation) > abs(value.translation.height) {
      if translation > dragThreshold || velocity > 300 {
        performAction(isAdd: true)
      } else if translation < -dragThreshold || velocity < -300 {
        performAction(isAdd: false)
      } else {
        resetCard()
      }
    } else {
      resetCard()
    }
  }

  private func performAction(isAdd: Bool) {
    guard !isProcessing else { return }
    isProcessing = true

    let targetOffset: CGFloat = isAdd ? 200 : -200

    withAnimation(.easeInOut(duration: animationDuration)) {
      dragOffset = targetOffset
      scale = 0.8
      opacity = 0.0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [self] in
      if isAdd {
        onCollect()
      } else {
        onLater()
      }

      DispatchQueue.main.async {
        dragOffset = 0
        scale = 1.0
        opacity = 1.0
        isProcessing = false
      }
    }
  }

  private func resetCard() {
    guard !isProcessing else { return }

    withAnimation(.easeOut(duration: 0.2)) {
      dragOffset = 0
      scale = 1.0
      opacity = 1.0
    }
  }

  private func resetState() {
    dragOffset = 0
    scale = 1.0
    opacity = 1.0
    isProcessing = false
  }

  private func loadImage(named imageName: String) -> UIImage? {
    if let bundledImage = UIImage(named: imageName) {
      return bundledImage
    }

    guard
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      return nil
    }

    let imageURL = documentsPath.appendingPathComponent("\(imageName).jpg")

    guard let data = try? Data(contentsOf: imageURL) else {
      return nil
    }

    return UIImage(data: data)
  }
}
