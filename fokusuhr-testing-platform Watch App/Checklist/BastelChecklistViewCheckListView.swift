import SwiftUI

struct BastelChecklistItem: Identifiable, ChecklistItem {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

struct BastelChecklistView: View {
    @EnvironmentObject var watchConnector: WatchConnector
    
    var body: some View {
        UniversalChecklistView(
            title: "Bastelsachen",
            instructionTitle: "Bastelsachen",
            items: watchConnector.checklistConfiguration.bastelItems
        )
    }
}

#Preview {
    BastelChecklistView()
        .environmentObject(WatchConnector())
}
