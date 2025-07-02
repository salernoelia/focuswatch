import SwiftUI

struct RezeptChecklistItem: Identifiable, ChecklistItem {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

struct RezeptChecklistView: View {
    private let items: [RezeptChecklistItem] = [
        RezeptChecklistItem(title: "100g Zucker", imageName: "Zucker", color: .gray),
        RezeptChecklistItem(title: "1 Ei", imageName: "Ei", color: .yellow),
        RezeptChecklistItem(title: "100g Haselnüsse", imageName: "Haselnüsse", color: .brown),
        RezeptChecklistItem(title: "75g Schokoladenpulver", imageName: "Schokoladenpulver", color: .brown),
        RezeptChecklistItem(title: "1 EL Maizena", imageName: "Maizena", color: .orange),
        RezeptChecklistItem(title: "1 Schüssel", imageName: "Schüssel", color: .blue),
        RezeptChecklistItem(title: "1 Kelle", imageName: "Kelle", color: .gray),
        RezeptChecklistItem(title: "1 Backblech", imageName: "Backblech", color: .gray),
        RezeptChecklistItem(title: "1 Backpapier", imageName: "Backpapier", color: .gray),
        RezeptChecklistItem(title: "1 Waage", imageName: "Waage", color: .green),
        RezeptChecklistItem(title: "1 Messlöffel", imageName: "Messlöffel", color: .purple),
        RezeptChecklistItem(title: "2 Topflappen", imageName: "Topflappen", color: .red)
    ]
    
    var body: some View {
        UniversalChecklistView(
            title: "Schoggikugeln",
            instructionTitle: "Schoggikugeln",
            items: items
        )
    }
}

#Preview {
    RezeptChecklistView()
}
