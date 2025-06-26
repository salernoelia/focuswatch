import SwiftUI

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

struct ChecklistView: View {
    @State private var items: [ChecklistItem] = [
        ChecklistItem(title: "Keys", imageName: "key.fill", color: .yellow),
        ChecklistItem(title: "Wallet", imageName: "creditcard.fill", color: .green),
        ChecklistItem(title: "Phone", imageName: "iphone", color: .blue),
        ChecklistItem(title: "Headphones", imageName: "headphones", color: .purple),
        ChecklistItem(title: "Water Bottle", imageName: "drop.fill", color: .cyan),
        ChecklistItem(title: "Sunglasses", imageName: "sun.max.fill", color: .orange)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        ChecklistCard(item: item) {
                            removeItem(item)
                        }
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 16)
                    }
                }
                .scrollTargetLayout()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: .constant(items.first?.id))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func removeItem(_ item: ChecklistItem) {
        withAnimation(.spring()) {
            items.removeAll { $0.id == item.id }
        }
    }
}

struct ChecklistCard: View {
    let item: ChecklistItem
    let onComplete: () -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var isCompleted = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: item.imageName)
                .font(.system(size: 48))
                .foregroundColor(.white)
            
            Text(item.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(item.color)
        )
        .scaleEffect(isCompleted ? 0.8 : 1.0)
        .opacity(isCompleted ? 0.3 : 1.0)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only respond to primarily vertical drags
                    if abs(value.translation.height) > abs(value.translation.width) && value.translation.height < 0 {
                        dragOffset = max(value.translation.height, -50)
                    }
                }
                .onEnded { value in
                    // Only complete if it's primarily a vertical drag
                    if abs(value.translation.height) > abs(value.translation.width) && value.translation.height < -30 {
                        completeItem()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            completeItem()
        }
    }
    
    private func completeItem() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isCompleted = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onComplete()
        }
    }
}

#Preview {
    ChecklistView()
}
