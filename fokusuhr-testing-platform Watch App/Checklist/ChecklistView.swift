import SwiftUI

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

enum ChecklistState {
    case instructions
    case checklist
    case completed
}

struct ChecklistView: View {
    @State private var allItems: [ChecklistItem] = [
        ChecklistItem(title: "Eine Schere", imageName: "scissors", color: .red),
        ChecklistItem(title: "Ein Lineal", imageName: "ruler", color: .blue),
        ChecklistItem(title: "Ein Bleistift", imageName: "pencil", color: .yellow),
        ChecklistItem(title: "Ein Leimstift", imageName: "gluestick", color: .purple),
        ChecklistItem(title: "Buntes Papier", imageName: "doc.fill", color: .green),
        ChecklistItem(title: "Wolle", imageName: "oval.fill", color: .pink),
        ChecklistItem(title: "Wackelaugen", imageName: "eye.fill", color: .cyan),
        ChecklistItem(title: "Locher", imageName: "circle.grid.cross.fill", color: .orange)
    ]
    
    @State private var remainingItems: [ChecklistItem] = []
    @State private var collectedItems: [ChecklistItem] = []
    @State private var currentIndex = 0
    @State private var state: ChecklistState = .instructions
    
    var body: some View {
        switch state {
        case .instructions:
            InstructionsView {
                withAnimation(.easeInOut) {
                    remainingItems = allItems
                    state = .checklist
                }
            }
        case .checklist:
            ChecklistMainView(
                remainingItems: $remainingItems,
                collectedItems: $collectedItems,
                currentIndex: $currentIndex,
                onComplete: {
                    withAnimation {
                        state = .completed
                    }
                }
            )
        case .completed:
            CompletionView()
        }
    }
}

struct InstructionsView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Bastelsachen")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.green)
                    Text("Rechts = Hab ich!")
                        .font(.caption2)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.orange)
                    Text("Links = Später")
                        .font(.caption2)
                }
            }
            
            Button("Loslegen") {
                onStart()
            }
        }
        .padding()
    }
}
struct ChecklistMainView: View {
    @Binding var remainingItems: [ChecklistItem]
    @Binding var collectedItems: [ChecklistItem]
    @Binding var currentIndex: Int
    let onComplete: () -> Void
    
    private let totalItems = 8
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                if currentIndex < remainingItems.count {
                    ChecklistCard(
                        item: remainingItems[currentIndex],
                        onAdd: addCurrentItem,
                        onSkip: skipCurrentItem
                    )
                    .id(remainingItems[currentIndex].id)
                } else if !remainingItems.isEmpty {
                    ChecklistCard(
                        item: remainingItems[0],
                        onAdd: addCurrentItem,
                        onSkip: skipCurrentItem
                    )
                    .id(remainingItems[0].id)
                    .onAppear {
                        currentIndex = 0
                    }
                }
                
                Spacer()
                
                ProgressIndicator(
                    totalItems: totalItems,
                    collectedCount: collectedItems.count
                )
                .padding(.bottom, 8)
            }
        }
    }
    
    private func addCurrentItem() {
        let item = remainingItems[currentIndex]
        collectedItems.append(item)
        remainingItems.remove(at: currentIndex)
        
        if remainingItems.isEmpty {
            onComplete()
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                if currentIndex >= remainingItems.count {
                    currentIndex = 0
                }
            }
        }
    }
    
    private func skipCurrentItem() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentIndex = (currentIndex + 1) % remainingItems.count
        }
    }
}

struct ProgressIndicator: View {
    let totalItems: Int
    let collectedCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalItems, id: \.self) { index in
                Circle()
                    .fill(index < collectedCount ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(index < collectedCount ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: collectedCount)
            }
        }
    }
}

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Super gemacht!")
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text("Alles gesammelt.")

        }

        
    }
}

struct ChecklistCard: View {
    let item: ChecklistItem
    let onAdd: () -> Void
    let onSkip: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var isProcessing = false
    
    private let dragThreshold: CGFloat = 40
    private let animationDuration: Double = 0.3
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: item.imageName)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.white)
            
            Text(item.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(item.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: strokeWidth)
                )
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
    }
    
    private var borderColor: Color {
        if abs(dragOffset) < 20 { return .clear }
        return dragOffset > 0 ? .green : .orange
    }
    
    private var strokeWidth: CGFloat {
        abs(dragOffset) > 20 ? 3 : 0
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        guard !isProcessing else { return }
        
        let translation = value.translation.width
        
        if abs(translation) > abs(value.translation.height) {
            dragOffset = translation
            
            let progress = min(abs(translation) / 100, 1.0)
            scale = 1.0 - (progress * 0.1)
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
        isProcessing = true
        
        let targetOffset: CGFloat = isAdd ? 200 : -200
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            dragOffset = targetOffset
            scale = 0.8
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            if isAdd {
                onAdd()
            } else {
                onSkip()
            }
            resetState()
        }
    }
    
    private func resetCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
}

#Preview {
    ChecklistView()
}
