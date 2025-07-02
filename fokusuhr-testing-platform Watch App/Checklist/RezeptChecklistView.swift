import SwiftUI

struct RezeptChecklistItem: Identifiable, ChecklistItem {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

struct RezeptChecklistView: View {
    @EnvironmentObject var watchConnector: WatchConnector
    
    var body: some View {
        UniversalChecklistView(
            title: "Schoggikugeln",
            instructionTitle: "Schoggikugeln",
            items: watchConnector.checklistConfiguration.rezeptItems
        )
    }
}

#Preview {
    RezeptChecklistView()
        .environmentObject(WatchConnector())
}
