import SwiftUI

struct ChecklistEditorView: View {
    @ObservedObject var checklistManager: ChecklistManager
    @State private var selectedTypeIndex = 0
    @State private var showingNewTypeForm = false
    @State private var showingImageManager = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if !checklistManager.configuration.checklistTypes.isEmpty {
                    Picker("Checklist Type", selection: $selectedTypeIndex) {
                        ForEach(Array(checklistManager.configuration.checklistTypes.enumerated()), id: \.offset) { index, type in
                            Text(type.displayName).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTypeIndex < checklistManager.configuration.checklistTypes.count {
                        ChecklistTypeEditor(
                            checklistType: binding(for: selectedTypeIndex),
                            availableImages: checklistManager.configuration.availableImages,
                            onDelete: {
                                checklistManager.deleteChecklistType(checklistManager.configuration.checklistTypes[selectedTypeIndex])
                                if selectedTypeIndex >= checklistManager.configuration.checklistTypes.count {
                                    selectedTypeIndex = max(0, checklistManager.configuration.checklistTypes.count - 1)
                                }
                            }
                        )
                    }
                } else {
                    VStack {
                        Text("No checklist types available")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Button("Add First Checklist Type") {
                            showingNewTypeForm = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Edit Checklists")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button("Images") {
                        showingImageManager = true
                    }
                    Button("Add Type") {
                        showingNewTypeForm = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingNewTypeForm) {
            NewChecklistTypeView(checklistManager: checklistManager)
        }
        .sheet(isPresented: $showingImageManager) {
            ImageManagerView(checklistManager: checklistManager)
        }
    }
    
    private func binding(for index: Int) -> Binding<ChecklistType> {
        return Binding(
            get: { checklistManager.configuration.checklistTypes[index] },
            set: { checklistManager.updateChecklistType($0) }
        )
    }
}

struct ChecklistTypeEditor: View {
    @Binding var checklistType: ChecklistType
    let availableImages: [String]
    let onDelete: () -> Void
    
    private let availableColors: [(String, Color)] = [
        ("red", .red), ("blue", .blue), ("yellow", .yellow), ("purple", .purple),
        ("green", .green), ("pink", .pink), ("cyan", .cyan), ("orange", .orange),
        ("gray", .gray), ("brown", .brown)
    ]
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Name:")
                    TextField("Display Name", text: $checklistType.displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("Color:")
                    Menu {
                        ForEach(availableColors, id: \.0) { colorName, color in
                            Button(colorName.capitalized) {
                                checklistType.colorName = colorName
                            }
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(checklistType.color)
                                .frame(width: 20, height: 20)
                            Text(checklistType.colorName.capitalized)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Button("Delete Type") {
                    onDelete()
                }
                .foregroundColor(.red)
                .font(.caption)
            }
            .padding()
            
            List {
                ForEach(checklistType.items) { item in
                    ChecklistItemRow(
                        item: binding(for: item),
                        availableImages: availableImages,
                        onDelete: {
                            checklistType.items.removeAll { $0.id == item.id }
                        }
                    )
                }
                .onDelete { indexSet in
                    checklistType.items.remove(atOffsets: indexSet)
                }
                
                Button("Add Item") {
                    let newItem = EditableChecklistItem(
                        title: "New Item",
                        imageName: availableImages.first ?? "Schere",
                        color: .blue
                    )
                    checklistType.items.append(newItem)
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private func binding(for item: EditableChecklistItem) -> Binding<EditableChecklistItem> {
        guard let index = checklistType.items.firstIndex(where: { $0.id == item.id }) else {
            fatalError("Item not found")
        }
        
        return Binding(
            get: { checklistType.items[index] },
            set: { checklistType.items[index] = $0 }
        )
    }
}

struct ChecklistItemRow: View {
    @Binding var item: EditableChecklistItem
    let availableImages: [String]
    let onDelete: () -> Void
    
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
                    ForEach(availableImages, id: \.self) { imageName in
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
                        Button(colorName.capitalized) {
                            item.colorName = colorName
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 20, height: 20)
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

struct NewChecklistTypeView: View {
    @ObservedObject var checklistManager: ChecklistManager
    @State private var name = ""
    @State private var displayName = ""
    @State private var selectedColor = Color.blue
    @Environment(\.presentationMode) var presentationMode
    
    private let availableColors: [(String, Color)] = [
        ("red", .red), ("blue", .blue), ("yellow", .yellow), ("purple", .purple),
        ("green", .green), ("pink", .pink), ("cyan", .cyan), ("orange", .orange),
        ("gray", .gray), ("brown", .brown)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Checklist Type Details") {
                    TextField("Internal Name", text: $name)
                    TextField("Display Name", text: $displayName)
                    
                    HStack {
                        Text("Color:")
                        Spacer()
                        Menu {
                            ForEach(availableColors, id: \.0) { colorName, color in
                                Button(colorName.capitalized) {
                                    selectedColor = color
                                }
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 20, height: 20)
                                Text("Select Color")
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Checklist Type")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let sanitizedName = name.lowercased().replacingOccurrences(of: " ", with: "_")
                    checklistManager.addChecklistType(
                        name: sanitizedName.isEmpty ? displayName.lowercased().replacingOccurrences(of: " ", with: "_") : sanitizedName,
                        displayName: displayName,
                        color: selectedColor
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(displayName.isEmpty)
            )
        }
    }
}

struct ImageManagerView: View {
    @ObservedObject var checklistManager: ChecklistManager
    @State private var newImageName = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section("Add New Image") {
                        HStack {
                            TextField("Image Name", text: $newImageName)
                            Button("Add") {
                                if !newImageName.isEmpty {
                                    checklistManager.addImageName(newImageName)
                                    newImageName = ""
                                }
                            }
                            .disabled(newImageName.isEmpty)
                        }
                    }
                    
                    Section("Available Images") {
                        ForEach(checklistManager.configuration.availableImages, id: \.self) { imageName in
                            HStack {
                                Text(imageName)
                                Spacer()
                                Button("Remove") {
                                    checklistManager.removeImageName(imageName)
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Images")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
