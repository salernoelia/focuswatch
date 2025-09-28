import SwiftUI
import PhotosUI

struct ChecklistEditorView: View {
    @ObservedObject var checklistManager: ChecklistManager
    @StateObject private var galleryStorage = GalleryStorage.shared
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
    @State private var showingPhotoPicker = false
    @State private var showingCameraPicker = false
    @State private var showingActionSheet = false
    @State private var selectedUIImage: UIImage?
    @State private var newImageLabel = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Select Image", selection: $selectedImage) {
                        Text("None").tag("")
                        ForEach(availableImages, id: \.self) { imageName in
                            Text(imageName).tag(imageName)
                        }
                    }
                    .disabled(selectedUIImage != nil)
                    
                    Button(selectedUIImage != nil ? "Replace Photo" : "Take New Photo") {
                        showingActionSheet = true
                    }
                    .foregroundColor(.blue)
                    
                    // Show preview of selected photo
                    if let newImage = selectedUIImage {
                        HStack {
                            Text("New Photo:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(uiImage: newImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                            Button("Remove") {
                                selectedUIImage = nil
                                if title == "New Item" {
                                    title = ""
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Image Selection")
                }
                
                Section {
                    TextField("Enter image label", text: $title)
                } header: {
                    Text("Image Label")
                }

               
            }
            .onChange(of: selectedImage) { newValue in
                if title.isEmpty {
                    title = newValue
                }
            }
            .navigationTitle("Add Image")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    var finalImageName = selectedImage
                    
                    // If we have a new photo, add it to gallery with the user's label
                    if let newImage = selectedUIImage, !title.isEmpty {
                        galleryStorage.addItem(image: newImage, label: title)
                        finalImageName = title
                    }
                    
                    let finalTitle = title.isEmpty ? (selectedImage.isEmpty ? "Untitled" : selectedImage) : title
                    
                    checklistManager.addItem(
                        to: checklist,
                        title: finalTitle,
                        imageName: finalImageName
                    )
                    checklist.items.append(
                        ChecklistItem(title: finalTitle, imageName: finalImageName)
                    )
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled((title.isEmpty && selectedImage.isEmpty && selectedUIImage == nil) || 
                         (selectedUIImage != nil && title.isEmpty))
            )
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Add Photo"),
                buttons: [
                    .default(Text("Camera")) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showingCameraPicker = true
                        }
                    },
                    .default(Text("Photo Library")) {
                        showingPhotoPicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(source: .photoLibrary) { images in
                if let image = images.first {
                    selectedUIImage = image
                    selectedImage = "" // Clear existing selection
                }
            }
        }
        .sheet(isPresented: $showingCameraPicker) {
            PhotoPicker(source: .camera) { images in
                if let image = images.first {
                    selectedUIImage = image
                    selectedImage = "" // Clear existing selection
                }
            }
        }
    }

    private var availableImages: [String] {
        let watchImages = ["Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", "Wackelaugen", "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver", "Maizena", "Schüssel", "Kelle", "Backblech", "Backpapier", "Waage", "Messlöffel", "Topflappen"]
        let galleryImages = galleryStorage.items.map { $0.label }
        return galleryImages + watchImages.filter { UIImage(named: $0) != nil }
    }
}

