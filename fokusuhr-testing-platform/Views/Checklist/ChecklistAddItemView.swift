import PhotosUI
import SwiftUI

struct ChecklistAddItemView: View {
  @Binding var checklist: Checklist
  @ObservedObject var checklistService: ChecklistSyncService
  @ObservedObject var galleryStorage: GalleryStorage
  @State private var title = ""
  @State private var selectedImage = ""
  @State private var showingPhotoPicker = false
  @State private var showingCameraPicker = false
  @State private var showingActionSheet = false
  @State private var selectedUIImage: UIImage?
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      Form {
        Section {
          if let newImage = selectedUIImage {
            HStack {
              Spacer()
              Image(uiImage: newImage)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(
                      Color.secondary.opacity(0.2),
                      lineWidth: 1
                    )
                )
              Spacer()
            }

            Button(role: .destructive) {
              selectedUIImage = nil
              if title == "New Item" {
                title = ""
              }
            } label: {
              Label("Remove Photo", systemImage: "trash")
            }
          } else if !selectedImage.isEmpty,
            let image = getSelectedImage()
          {
            HStack {
              Spacer()
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(
                      Color.secondary.opacity(0.2),
                      lineWidth: 1
                    )
                )
              Spacer()
            }
          }
        } header: {
          Text("Preview")
        }

        Section {
          TextField("Enter label", text: $title)
        } header: {
          Text("Label")
        } footer: {
          Text("This label will be displayed alongside the image")
        }

        Section {
          Picker("Image", selection: $selectedImage) {
            Text("None").tag("")
            ForEach(availableImages, id: \.self) { imageName in
              Text(imageName).tag(imageName)
            }
          }
          .disabled(selectedUIImage != nil)

          Button {
            showingActionSheet = true
          } label: {
            Label(
              selectedUIImage != nil
                ? "Bild Ersetzen" : "Neues Bild Hinzufügen",
              systemImage: "camera"
            )
          }
        } header: {
          Text("Image Selection")
        }

      }
      .onChange(of: selectedImage, initial: false) { _, newValue in
        if title.isEmpty {
          title = newValue
        }
      }
      .navigationTitle("Add Item")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            var finalImageName = selectedImage

            if let newImage = selectedUIImage, !title.isEmpty {
              galleryStorage.addItem(
                image: newImage,
                label: title
              )
              finalImageName = title
            }

            let finalTitle =
              title.isEmpty
              ? (selectedImage.isEmpty
                ? "Untitled" : selectedImage) : title

            let newItem = ChecklistItem(title: finalTitle, imageName: finalImageName)
            checklist.items.append(newItem)

            var data = checklistService.checklistData
            if let index = data.checklists.firstIndex(where: { $0.id == checklist.id }) {
              data.checklists[index] = checklist
              checklistService.updateChecklistData(data)
            }

            presentationMode.wrappedValue.dismiss()
          }
          .disabled(
            (title.isEmpty && selectedImage.isEmpty
              && selectedUIImage == nil)
              || (selectedUIImage != nil && title.isEmpty)
          )
          .fontWeight(.semibold)
        }
      }
    }
    .actionSheet(isPresented: $showingActionSheet) {
      ActionSheet(
        title: Text("Add Photo"),
        buttons: [
          .default(Text("Camera")) {
            if UIImagePickerController.isSourceTypeAvailable(
              .camera
            ) {
              showingCameraPicker = true
            }
          },
          .default(Text("Bilder")) {
            showingPhotoPicker = true
          },
          .cancel(),
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
    let watchImages = [
      "Schere", "Lineal", "Bleistift", "Leimstift", "Buntes Papier",
      "Wolle", "Wackelaugen",
      "Locher", "Zucker", "Ei", "Haselnüsse", "Schokoladenpulver",
      "Maizena", "Schüssel", "Kelle",
      "Backblech", "Backpapier", "Waage", "Messlöffel", "Topflappen",
    ]
    let galleryImages = galleryStorage.items.map { $0.label }
    return galleryImages + watchImages.filter { UIImage(named: $0) != nil }
  }

  private func getSelectedImage() -> UIImage? {
    if let galleryItem = galleryStorage.items.first(where: {
      $0.label == selectedImage
    }) {
      return galleryItem.image
    }
    return UIImage(named: selectedImage)
  }
}
