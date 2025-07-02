import SwiftUI

struct BastelChecklistItem: Identifiable, ChecklistItem {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

struct BastelChecklistView: View {
    private let items: [BastelChecklistItem] = [
        BastelChecklistItem(title: "Eine Schere", imageName: "Schere", color: .red),
        BastelChecklistItem(title: "Ein Lineal", imageName: "Lineal", color: .blue),
        BastelChecklistItem(title: "Ein Bleistift", imageName: "Bleistift", color: .yellow),
        BastelChecklistItem(title: "Ein Leimstift", imageName: "Leimstift", color: .purple),
        BastelChecklistItem(title: "Buntes Papier", imageName: "Buntes Papier", color: .green),
        BastelChecklistItem(title: "Wolle", imageName: "Wolle", color: .pink),
        BastelChecklistItem(title: "Wackelaugen", imageName: "Wackelaugen", color: .cyan),
        BastelChecklistItem(title: "Locher", imageName: "Locher", color: .orange)
    ]
    
    var body: some View {
        UniversalChecklistView(
            title: "Bastelsachen",
            instructionTitle: "Bastelsachen",
            items: items
        )
    }
}

#Preview {
    BastelChecklistView()
}
