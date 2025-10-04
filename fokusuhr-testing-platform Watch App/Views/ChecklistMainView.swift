import SwiftUI

struct ChecklistMainView<Item: ChecklistItemProtocol>: View {
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
                
                if !remainingItems.isEmpty && currentIndex < remainingItems.count {
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
        guard !remainingItems.isEmpty, currentIndex < remainingItems.count else { return }
        let item = remainingItems[currentIndex]
        collectedItems.append(item)
        remainingItems.remove(at: currentIndex)
        VibrationManager.shared.mediumVibration()
        
        if remainingItems.isEmpty {
            VibrationManager.shared.strongVibration()
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
        guard !remainingItems.isEmpty else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentIndex = (currentIndex + 1) % remainingItems.count
        }
    }
}
