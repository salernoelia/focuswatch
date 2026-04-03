import SwiftUI

struct ChecklistCard<Item: ChecklistItemProtocol>: View {
    let item: Item
    let swipeMapping: ChecklistSwipeDirectionMapping
    let promptText: String?
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

            if let promptText {
                Text(promptText)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
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
                    fallbackColor
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
        if dragOffset > 0 {
            return swipeMapping.collectDirection == .right ? .green : .yellow
        }
        return swipeMapping.collectDirection == .left ? .green : .yellow
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
                performAction(direction: .right)
            } else if translation < -dragThreshold || velocity < -300 {
                performAction(direction: .left)
            } else {
                resetCard()
            }
        } else {
            resetCard()
        }
    }

    private func performAction(direction: ChecklistSwipeDirection) {
        guard !isProcessing else { return }
        isProcessing = true

        let targetOffset: CGFloat = direction == .right ? 200 : -200
        let shouldCollect = direction == swipeMapping.collectDirection

        withAnimation(.easeInOut(duration: animationDuration)) {
            dragOffset = targetOffset
            scale = 0.8
            opacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [self] in
            if shouldCollect {
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

    private var fallbackColor: Color {
        let palette: [Color] = [
            Color(red: 0.18, green: 0.45, blue: 0.78),
            Color(red: 0.12, green: 0.58, blue: 0.49),
            Color(red: 0.79, green: 0.46, blue: 0.16),
            Color(red: 0.69, green: 0.28, blue: 0.36),
            Color(red: 0.41, green: 0.33, blue: 0.74),
        ]

        let hash = item.title.unicodeScalars.reduce(0) { partialResult, scalar in
            (partialResult &* 31 &+ Int(scalar.value))
        }

        return palette[abs(hash) % palette.count].opacity(0.8)
    }

    private func loadImage(named imageName: String) -> UIImage? {
        guard !imageName.isEmpty else {
            return nil
        }

        if let bundledImage = UIImage(named: imageName) {
            return bundledImage
        }

        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            )
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
