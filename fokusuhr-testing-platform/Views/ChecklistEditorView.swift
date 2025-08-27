import SwiftUI

struct ChecklistEditorView: View {
    @ObservedObject var checklistManager: ChecklistManager
    @StateObject private var galleryStorage = GalleryStorage()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(checklistManager.data.checklists) { checklist in
                    NavigationLink(destination: ChecklistDetailView(checklist: checklist, checklistManager: checklistManager, galleryStorage: galleryStorage)) {
                        Text(checklist.name)
                    }   
                }
                .onDelete(perform: deleteChecklists)
                
                Button("Add Checklist") {
                    checklistManager.addChecklist(name: "New Checklist")
                }
            }
            .navigationTitle("Checklists")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func deleteChecklists(offsets: IndexSet) {
        for index in offsets {
            checklistManager.deleteChecklist(checklistManager.data.checklists[index])
        }
    }
}

struct ChecklistDetailView: View {
    @State var checklist: Checklist
    @ObservedObject var checklistManager: ChecklistManager
    @ObservedObject var galleryStorage: GalleryStorage
    @State private var showingAddItem = false
    
    var body: some View {
        List {
            Section {
                TextField("Checklist Name", text: $checklist.name)
                    .onSubmit {
                        checklistManager.updateChecklist(checklist)
                    }
            }
            
            Section("Items") {
                ForEach(checklist.items) { item in
                    ChecklistItemEditRow(item: item, checklist: $checklist, checklistManager: checklistManager, galleryStorage: galleryStorage)
                }
                .onDelete(perform: deleteItems)
                
                Button("Add Item") {
                    showingAddItem = true
                }
            }
        }
        .navigationTitle(checklist.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) {
            AddItemView(checklist: $checklist, checklistManager: checklistManager, galleryStorage: galleryStorage)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = checklist.items[index]
            checklistManager.deleteItem(from: checklist, item: item)
            checklist.items.remove(at: index)
        }
    }
}

struct ChecklistItemEditRow: View {
    @State var item: ChecklistItem
    @Binding var checklist: Checklist
    @ObservedObject var checklistManager: ChecklistManager
    @ObservedObject var galleryStorage: GalleryStorage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                TextField("Item title", text: $item.title)
                    .onSubmit {
                        updateItem()
                    }
                
                Menu("Image: \(item.imageName.isEmpty ? "None" : item.imageName)") {
                    Button("None") {
                        item.imageName = ""
                        updateItem()
                    }
                    
                    ForEach(availableImages, id: \.self) { imageName in
                        Button(imageName) {
                            item.imageName = imageName
                            updateItem()
                        }
                    }
                }
                .font(.caption)
            }
            
            if !item.imageName.isEmpty {
                if UIImage(named: item.imageName) != nil {
                    Image(item.imageName)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Image(systemName: "photo")
                        .frame(width: 30, height: 30)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var availableImages: [String] {
        let watchImages = ["Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", "Wackelaugen", "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver", "Maizena", "Schüssel", "Kelle", "Backblech", "Backpapier", "Waage", "Messlöffel", "Topflappen"]
        let galleryImages = galleryStorage.items.map { $0.label }
        return galleryImages + watchImages.filter { UIImage(named: $0) != nil }
    }
    
    private func updateItem() {
        if let index = checklist.items.firstIndex(where: { $0.id == item.id }) {
            checklist.items[index] = item
            checklistManager.updateChecklist(checklist)
        }
    }
}

struct AddItemView: View {
    @Binding var checklist: Checklist
    @ObservedObject var checklistManager: ChecklistManager
    @ObservedObject var galleryStorage: GalleryStorage
    @State private var title = ""
    @State private var selectedImage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Item title", text: $title)
                
                Section("Image") {
                    Picker("Select Image", selection: $selectedImage) {
                        Text("None").tag("")
                        ForEach(availableImages, id: \.self) { imageName in
                            Text(imageName).tag(imageName)
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    checklistManager.addItem(to: checklist, title: title, imageName: selectedImage)
                    checklist.items.append(ChecklistItem(title: title, imageName: selectedImage))
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private var availableImages: [String] {
        let watchImages = ["Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", "Wackelaugen", "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver", "Maizena", "Schüssel", "Kelle", "Backblech", "Backpapier", "Waage", "Messlöffel", "Topflappen"]
        let galleryImages = galleryStorage.items.map { $0.label }
        return galleryImages + watchImages.filter { UIImage(named: $0) != nil }
    }
}
