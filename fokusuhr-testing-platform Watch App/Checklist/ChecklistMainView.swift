import SwiftUI

struct ChecklistMainView<Item: ChecklistItem>: View {
    @Binding var remainingItems: [Item]
    @Binding var collectedItems: [Item]
    @Binding var currentIndex: Int
    let totalItems: Int
    let onComplete: () -> Void
    
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
                
                ChecklistProgressIndicator(
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