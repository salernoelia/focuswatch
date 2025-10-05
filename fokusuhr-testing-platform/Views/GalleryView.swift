import SwiftUI
import PhotosUI

struct GalleryView: View {
    @EnvironmentObject private var galleryStorage: GalleryStorage
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
            case .medium: return 120
            case .large: return 160
            }
        }
    }
    
    private var filteredItems: [GalleryItemModel] {
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
                                GalleryItemCard(item: item, size: selectedGridSize.itemSize, galleryStorage: galleryStorage)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .searchable(text: $searchText, prompt: "Search images...")
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Grid Size", selection: $selectedGridSize) {
                            ForEach(GridSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                    } label: {
                        Image(systemName: "square.grid.3x3")
                    }
                    
                    Button(action: { showingActionSheet = true }) {
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
                        .cancel()
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
                    VStack(spacing: 20) {
                        if let image = selectedImages.first {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter a label for your photo:")
                                .font(.headline)
                            
                            TextField("Photo label", text: $newImageLabel)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit {
                                    if let image = selectedImages.first {
                                        let label = newImageLabel.isEmpty ? "Untitled" : newImageLabel
                                        galleryStorage.addItem(image: image, label: label)
                                        newImageLabel = ""
                                        selectedImages = []
                                        showingLabelInput = false
                                    }
                                }
                        }
                        
                        Spacer()
                    }
                    .padding()
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
                                if let image = selectedImages.first {
                                    let label = newImageLabel.isEmpty ? "Untitled" : newImageLabel
                                    galleryStorage.addItem(image: image, label: label)
                                    newImageLabel = ""
                                    selectedImages = []
                                    showingLabelInput = false
                                }
                            }
                        
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Photos")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add photos to your gallery to use them in checklists and other apps")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingActionSheet = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add First Photo")
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}


