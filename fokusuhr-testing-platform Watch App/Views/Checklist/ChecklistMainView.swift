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

        if !remainingItems.isEmpty, 
           currentIndex >= 0,
           currentIndex < remainingItems.count {
          ChecklistCard(
            item: remainingItems[currentIndex],
            onAdd: addCurrentItem,
            onSkip: skipCurrentItem
          )
          .id(remainingItems[currentIndex].id)
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
    guard !remainingItems.isEmpty, 
          currentIndex >= 0,
          currentIndex < remainingItems.count else { 
      #if DEBUG
      print("Warning: Invalid state for addCurrentItem - remainingItems: \(remainingItems.count), currentIndex: \(currentIndex)")
      #endif
      return 
    }
    
    let item = remainingItems[currentIndex]
    collectedItems.append(item)
    remainingItems.remove(at: currentIndex)
    VibrationManager.shared.mediumVibration()

    if remainingItems.isEmpty {
      VibrationManager.shared.strongVibration()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        onComplete()
      }
    } else {
      // Ensure currentIndex is within bounds after removal
      if currentIndex >= remainingItems.count {
        currentIndex = 0
      }
      // Additional safety check
      currentIndex = max(0, min(currentIndex, remainingItems.count - 1))
    }
  }

  private func skipCurrentItem() {
    guard !remainingItems.isEmpty else { return }
    // Safe modulo operation with bounds checking
    currentIndex = (currentIndex + 1) % remainingItems.count
    // Additional bounds check to ensure index is always valid
    currentIndex = max(0, min(currentIndex, remainingItems.count - 1))
  }
}
