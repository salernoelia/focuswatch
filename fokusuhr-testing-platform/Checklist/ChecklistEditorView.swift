import SwiftUI

struct ChecklistEditorView: View {
    @ObservedObject var watchConnector: WatchConnector
    @State private var editingConfiguration: ChecklistConfiguration
    @State private var selectedTab = 0
    @State private var showingGallery = false
    @Environment(\.presentationMode) var presentationMode
    
    init(watchConnector: WatchConnector) {
        self.watchConnector = watchConnector
        self._editingConfiguration = State(initialValue: watchConnector.checklistConfiguration)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Checklist Type", selection: $selectedTab) {
                    Text("Bastelsachen").tag(0)
                    Text("Rezept").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                List {
                    ForEach(selectedTab == 0 ? editingConfiguration.bastelItems : editingConfiguration.rezeptItems) { item in
                        ChecklistItemRow(
                            item: binding(for: item, in: selectedTab == 0 ? \.bastelItems : \.rezeptItems),
                            onDelete: {
                                deleteItem(item, from: selectedTab == 0 ? \.bastelItems : \.rezeptItems)
                            },
                            watchConnector: watchConnector
                        )
                    }
                    .onDelete { indexSet in
                        if selectedTab == 0 {
                            editingConfiguration.bastelItems.remove(atOffsets: indexSet)
                        } else {
                            editingConfiguration.rezeptItems.remove(atOffsets: indexSet)
                        }
                    }
                    
                    Button("Add Item") {
                        let newItem = EditableChecklistItem(title: "New Item", imageName: "Schere", color: .blue)
                        if selectedTab == 0 {
                            editingConfiguration.bastelItems.append(newItem)
                        } else {
                            editingConfiguration.rezeptItems.append(newItem)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Edit Checklists")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button("Gallery") {
                        showingGallery = true
                    }
                    Button("Save") {
                        watchConnector.updateChecklistConfiguration(editingConfiguration)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showingGallery) {
            ImageGalleryView(watchConnector: watchConnector)
        }
    }
    
    private func binding(for item: EditableChecklistItem, in keyPath: WritableKeyPath<ChecklistConfiguration, [EditableChecklistItem]>) -> Binding<EditableChecklistItem> {
        guard let index = editingConfiguration[keyPath: keyPath].firstIndex(where: { $0.id == item.id }) else {
            fatalError("Item not found")
        }
        
        return Binding(
            get: { editingConfiguration[keyPath: keyPath][index] },
            set: { editingConfiguration[keyPath: keyPath][index] = $0 }
        )
    }
    
    private func deleteItem(_ item: EditableChecklistItem, from keyPath: WritableKeyPath<ChecklistConfiguration, [EditableChecklistItem]>) {
        editingConfiguration[keyPath: keyPath].removeAll { $0.id == item.id }
    }
}

struct ChecklistItemRow: View {
    @Binding var item: EditableChecklistItem
    let onDelete: () -> Void
    @ObservedObject var watchConnector: WatchConnector
    
    private let builtInImages = [
        "Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", 
        "Wackelaugen", "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver",
        "Maizena", "Schüssel", "Kelle", "Backblech", "Backpapier", "Waage",
        "Messlöffel", "Topflappen"
    ]
    
    private var allAvailableImages: [String] {
        return builtInImages + watchConnector.checklistConfiguration.customImages
    }
    
    private let availableColors: [(String, Color)] = [
        ("red", .red), ("blue", .blue), ("yellow", .yellow), ("purple", .purple),
        ("green", .green), ("pink", .pink), ("cyan", .cyan), ("orange", .orange),
        ("gray", .gray), ("brown", .brown)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Title", text: $item.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Delete") {
                    onDelete()
                }
                .foregroundColor(.red)
                .font(.caption)
            }
            
            HStack {
                Text("Image:")
                Menu(item.imageName) {
                    ForEach(allAvailableImages, id: \.self) { imageName in
                        Button(imageName) {
                            item.imageName = imageName
                        }
                    }
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("Color:")
                Menu {
                    ForEach(availableColors, id: \.0) { colorName, color in
                        Button(action: {
                            item.colorName = colorName
                        }) {
                            HStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 16, height: 16)
                                Text(colorName.capitalized)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 16, height: 16)
                        Text(item.colorName.capitalized)
                    }
                    .foregroundColor(.blue)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
