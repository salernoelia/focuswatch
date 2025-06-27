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
    case retry
    case completed
}

struct ChecklistView: View {
    @State private var items: [ChecklistItem] = [
        ChecklistItem(title: "Eine Schere", imageName: "scissors", color: .red),
        ChecklistItem(title: "Ein Lineal", imageName: "ruler", color: .blue),
        ChecklistItem(title: "Ein Bleistift", imageName: "pencil", color: .yellow),
        ChecklistItem(title: "Ein Leimstift", imageName: "gluestick", color: .purple),
        ChecklistItem(title: "Buntes Papier", imageName: "doc.fill", color: .green),
        ChecklistItem(title: "Wolle", imageName: "oval.fill", color: .pink),
        ChecklistItem(title: "Wackelaugen", imageName: "eye.fill", color: .cyan),
        ChecklistItem(title: "Locher", imageName: "circle.grid.cross.fill", color: .orange)
    ]
    
    @State private var skippedItems: [ChecklistItem] = []
    @State private var currentIndex = 0
    @State private var state: ChecklistState = .instructions
    
    var body: some View {
        switch state {
        case .instructions:
            InstructionsView {
                withAnimation(.easeInOut) {
                    state = .checklist
                }
            }
        case .checklist:
            ChecklistMainView(
                items: items,
                currentIndex: $currentIndex,
                skippedItems: $skippedItems,
                onComplete: {
                    withAnimation {
                        state = skippedItems.isEmpty ? .completed : .retry
                    }
                }
            )
        case .retry:
            RetryView {
                restartWithSkipped()
            }
        case .completed:
            CompletionView()
        }
    }
    
    private func restartWithSkipped() {
        withAnimation {
            items = skippedItems
            skippedItems = []
            currentIndex = 0
            state = .checklist
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
    let items: [ChecklistItem]
    @Binding var currentIndex: Int
    @Binding var skippedItems: [ChecklistItem]
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if currentIndex < items.count {
                ChecklistCard(
                    item: items[currentIndex],
                    onAdd: addCurrentItem,
                    onSkip: skipCurrentItem
                )
                .id(items[currentIndex].id)
            }
        }
    }
    
    private func addCurrentItem() {
        advanceToNext()
    }
    
    private func skipCurrentItem() {
        skippedItems.append(items[currentIndex])
        advanceToNext()
    }
    
    private func advanceToNext() {
        if currentIndex < items.count - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentIndex += 1
            }
        } else {
            onComplete()
        }
    }
}

struct RetryView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Nochmal versuchen?")
                .font(.headline)
                .foregroundColor(.white)
            
            Button("Ja, nochmal!") {
                onRetry()
            }
           
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Super gemacht!")
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text("Alle Sachen gesammelt!")
                .fontWeight(.bold)


        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.green, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
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
