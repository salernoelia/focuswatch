import PhotosUI
import SwiftUI

struct GalleryView: View {
  @StateObject private var galleryStorage = GalleryStorage.shared
  @State private var showingPhotoPicker = false
  @State private var showingCameraPicker = false
  @State private var showingActionSheet = false
  @State private var newImageLabel = ""
  @State private var selectedImages: [UIImage] = []
  @State private var showingLabelInput = false
  @State private var searchText = ""
  @State private var selectedGridSize: GridSize = .medium

  enum GridSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var columns: [GridItem] {
      switch self {
      case .small:
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
      case .medium:
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
      case .large:
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
      }
    }

    var itemSize: CGFloat {
      switch self {
      case .small: return 80
      case .medium: return 100
      case .large: return 150
      }
    }
  }

  private var filteredItems: [GalleryItem] {
    if searchText.isEmpty {
      return galleryStorage.items
    }
    return galleryStorage.items.filter { item in
      item.label.localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    NavigationView {
      Group {
        if galleryStorage.items.isEmpty {
          emptyStateView
        } else {
          ScrollView {
            LazyVGrid(columns: selectedGridSize.columns, spacing: 12) {
              ForEach(filteredItems) { item in
                GalleryItemCard(
                  item: item, size: selectedGridSize.itemSize, galleryStorage: galleryStorage)
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
          }
          .searchable(text: $searchText, prompt: "Search items")
        }
      }
      .navigationTitle("Checklist Items")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          if !galleryStorage.items.isEmpty {
            Menu {
              Picker("Grid Size", selection: $selectedGridSize) {
                ForEach(GridSize.allCases, id: \.self) { size in
                  Label(size.rawValue, systemImage: gridIcon(for: size))
                    .tag(size)
                }
              }
            } label: {
              Image(systemName: "square.grid.3x3")
            }
          }

          Button {
            showingActionSheet = true
          } label: {
            Image(systemName: "plus")
          }
        }
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
            .cancel(),
          ]
        )
      }
      .sheet(isPresented: $showingPhotoPicker) {
        PhotoPicker(source: .photoLibrary) { images in
          selectedImages = images
          if !images.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              showingLabelInput = true
            }
          }
        }
      }
      .sheet(isPresented: $showingCameraPicker) {
        PhotoPicker(source: .camera) { images in
          selectedImages = images
          if !images.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              showingLabelInput = true
            }
          }
        }
      }
      .sheet(isPresented: $showingLabelInput) {
        NavigationView {
          Form {
            Section {
              if let image = selectedImages.first {
                HStack {
                  Spacer()
                  Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                  Spacer()
                }
              }
            }

            Section {
              TextField("Photo label", text: $newImageLabel)
                .submitLabel(.done)
                .onSubmit {
                  savePhoto()
                }
            } header: {
              Text("Label")
            } footer: {
              Text("Enter a descriptive label for your photo")
            }
          }
          .navigationTitle("Add Photo")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
              Button("Cancel") {
                newImageLabel = ""
                selectedImages = []
                showingLabelInput = false
              }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
              Button("Add") {
                savePhoto()
              }
              .fontWeight(.semibold)
            }
          }
        }
      }
    }
  }

  private func gridIcon(for size: GridSize) -> String {
    switch size {
    case .small: return "square.grid.4x3.fill"
    case .medium: return "square.grid.3x2"
    case .large: return "square.grid.2x2"
    }
  }

  private func savePhoto() {
    if let image = selectedImages.first {
      let label = newImageLabel.isEmpty ? "Untitled" : newImageLabel
      galleryStorage.addItem(image: image, label: label)
      newImageLabel = ""
      selectedImages = []
      showingLabelInput = false
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 24) {
      Image(systemName: "photo.on.rectangle.angled")
        .font(.system(size: 64))
        .foregroundColor(.secondary)

      VStack(spacing: 8) {
        Text("No Photos")
          .font(.title2)
          .fontWeight(.semibold)

        Text("Add photos to use in checklists")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }

      Button {
        showingActionSheet = true
      } label: {
        Label("Add Photo", systemImage: "plus")
          .font(.headline)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(Color.accentColor)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
    }
    .padding()
  }
}
