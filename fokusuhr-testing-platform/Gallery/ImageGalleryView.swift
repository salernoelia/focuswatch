import SwiftUI
import UIKit

struct ImageGalleryView: View {
    @ObservedObject var watchConnector: WatchConnector
    @State private var editingConfiguration: ChecklistConfiguration
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    private let builtInImages = [
        "Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier", "Wolle", 
        "Wackelaugen", "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver",
        "Maizena", "Schüssel", "Kelle", "Backblech", "Backpapier", "Waage",
        "Messlöffel", "Topflappen"
    ]
    
    init(watchConnector: WatchConnector) {
        self.watchConnector = watchConnector
        self._editingConfiguration = State(initialValue: watchConnector.checklistConfiguration)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    
                    Section("Built-in Images") {
                        ForEach(builtInImages, id: \.self) { imageName in
                            ImageCard(
                                imageName: imageName,
                                isBuiltIn: true,
                                onDelete: nil,
                                displayNameMapping: editingConfiguration.imageDisplayNames
                            )
                        }
                    }
                    
                    Section("Custom Images") {
                        ForEach(editingConfiguration.customImages, id: \.self) { imageName in
                            ImageCard(
                                imageName: imageName,
                                isBuiltIn: false,
                                onDelete: {
                                    deleteCustomImage(imageName)
                                },
                                onRename: { newName in
                                    renameCustomImage(imageName, to: newName)
                                },
                                displayNameMapping: editingConfiguration.imageDisplayNames
                            )
                        }
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                Text("Add Image")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Image Gallery")
            .navigationBarItems(
                trailing: Button("Done") {
                    watchConnector.updateChecklistConfiguration(editingConfiguration)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                saveSelectedImage(image)
            }
        }
        .alert("Image Gallery", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveSelectedImage(_ image: UIImage) {
        let imageName = "custom_\(UUID().uuidString)"
        
        if ImageManager.shared.saveImage(image, withName: imageName) {
            editingConfiguration.customImages.append(imageName)
        } else {
            alertMessage = "Failed to save image"
            showingAlert = true
        }
    }
    
    private func deleteCustomImage(_ imageName: String) {
        if ImageManager.shared.deleteImage(named: imageName) {
            editingConfiguration.customImages.removeAll { $0 == imageName }
            editingConfiguration.imageDisplayNames.removeValue(forKey: imageName)
        } else {
            alertMessage = "Failed to delete image"
            showingAlert = true
        }
    }
    
    private func renameCustomImage(_ imageName: String, to newName: String) {
        editingConfiguration.imageDisplayNames[imageName] = newName
    }
}



