import SwiftUI
import PhotosUI

struct ChecklistAddItemView: View {
    let checklist: ChecklistModel
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
                    selectedImage = "" 
                }
            }
        }
        .sheet(isPresented: $showingCameraPicker) {
            PhotoPicker(source: .camera) { images in
                if let image = images.first {
                    selectedUIImage = image
                    selectedImage = "" 
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