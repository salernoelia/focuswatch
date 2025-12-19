import PhotosUI
import SwiftUI

struct UnifiedAddItemsView: View {
  @Binding var checklist: Checklist
  @ObservedObject var checklistService: ChecklistSyncService
  @ObservedObject var galleryStorage: GalleryStorage
  @Environment(\.presentationMode) var presentationMode
  
  @State private var pendingItems: [PendingItem] = []
  @State private var showingPhotoPicker = false
  @State private var showingCameraPicker = false
  @State private var showingGalleryPicker = false
  @State private var selectedPhotoItems: [PhotosPickerItem] = []
  @FocusState private var focusedField: UUID?
  
  struct PendingItem: Identifiable {
    let id = UUID()
    var image: UIImage
    var label: String
  }
  
  var body: some View {
    NavigationView {
      Group {
        if pendingItems.isEmpty {
          emptyStateView
        } else {
          itemListView
        }
      }
      .navigationTitle(pendingItems.isEmpty ? NSLocalizedString("Add Items", comment: "") : "\(pendingItems.count)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(pendingItems.isEmpty ? NSLocalizedString("Cancel", comment: "") : NSLocalizedString("Back", comment: "")) {
            if pendingItems.isEmpty {
              presentationMode.wrappedValue.dismiss()
            } else {
              focusedField = nil
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pendingItems.removeAll()
              }
            }
          }
        }
        
        if !pendingItems.isEmpty {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(NSLocalizedString("Done", comment: "")) {
              focusedField = nil
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                saveAllItems()
                presentationMode.wrappedValue.dismiss()
              }
            }
            .fontWeight(.semibold)
            .disabled(pendingItems.contains { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
          }
        }
      }
    }
    .photosPicker(
      isPresented: $showingPhotoPicker,
      selection: $selectedPhotoItems,
      maxSelectionCount: 20,
      matching: .images
    )
    .onChange(of: selectedPhotoItems) { _, newItems in
      loadSelectedPhotos(newItems)
    }
    .sheet(isPresented: $showingCameraPicker) {
      PhotoPicker(source: .camera) { images in
        for image in images {
          addPendingItem(image: image, suggestedLabel: "")
        }
      }
    }
    .sheet(isPresented: $showingGalleryPicker) {
      GalleryMultiSelectView(galleryStorage: galleryStorage) { selectedItems in
        for item in selectedItems {
          if let image = item.image {
            addPendingItem(image: image, suggestedLabel: item.label)
          }
        }
      }
    }
  }
  
  private var emptyStateView: some View {
    VStack(spacing: 24) {
      Spacer()
      
      Image(systemName: "photo.on.rectangle.angled")
        .font(.system(size: 64))
        .foregroundColor(.secondary.opacity(0.5))
      
      Text(NSLocalizedString("Add Photos", comment: ""))
        .font(.title2)
        .fontWeight(.semibold)
      
      Text(NSLocalizedString("Select one or multiple photos to label and add", comment: ""))
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      
      Spacer()
      
      VStack(spacing: 12) {
        Button {
          showingPhotoPicker = true
        } label: {
          HStack {
            Image(systemName: "photo.on.rectangle")
            Text(NSLocalizedString("Choose Photos", comment: ""))
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        
        Button {
          showingCameraPicker = true
        } label: {
          HStack {
            Image(systemName: "camera")
            Text(NSLocalizedString("Take Photo", comment: ""))
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.secondary.opacity(0.15))
          .foregroundColor(.primary)
          .cornerRadius(12)
        }
        
        Button {
          showingGalleryPicker = true
        } label: {
          HStack {
            Image(systemName: "square.grid.2x2")
            Text(NSLocalizedString("Existing Items", comment: ""))
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.secondary.opacity(0.15))
          .foregroundColor(.primary)
          .cornerRadius(12)
        }
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 40)
    }
  }
  
  private var itemListView: some View {
    VStack(spacing: 0) {
      List {
        ForEach($pendingItems) { $item in
          HStack(spacing: 12) {
            Image(uiImage: item.image)
              .resizable()
              .scaledToFill()
              .frame(width: 60, height: 60)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
              )
            
            TextField(NSLocalizedString("Label", comment: ""), text: $item.label)
              .font(.body)
              .focused($focusedField, equals: item.id)
              .submitLabel(.next)
              .onSubmit {
                focusNextField(after: item.id)
              }
          }
          .padding(.vertical, 4)
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
              let itemId = item.id
              if focusedField == itemId {
                focusedField = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  withAnimation {
                    pendingItems.removeAll { $0.id == itemId }
                  }
                }
              } else {
                withAnimation {
                  pendingItems.removeAll { $0.id == itemId }
                }
              }
            } label: {
              Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
            }
          }
        }
      }
      .listStyle(.plain)
      
      VStack(spacing: 0) {
        Divider()
        
        HStack(spacing: 8) {
          Button {
            showingPhotoPicker = true
          } label: {
            HStack(spacing: 6) {
              Image(systemName: "photo.badge.plus")
                .font(.body)
              Text(NSLocalizedString("Photos", comment: ""))
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(10)
          }
          
          Button {
            showingCameraPicker = true
          } label: {
            HStack(spacing: 6) {
              Image(systemName: "camera")
                .font(.body)
              Text(NSLocalizedString("Camera", comment: ""))
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(10)
          }
          
          Button {
            showingGalleryPicker = true
          } label: {
            HStack(spacing: 6) {
              Image(systemName: "square.grid.2x2")
                .font(.body)
              Text(NSLocalizedString("Items", comment: ""))
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(10)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemBackground))
      }
    }
    .onAppear {
      if let firstItem = pendingItems.first {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          focusedField = firstItem.id
        }
      }
    }
  }
  
  private func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
    for item in items {
      item.loadTransferable(type: Data.self) { result in
        switch result {
        case .success(let data):
          if let data = data, let image = UIImage(data: data) {
            DispatchQueue.main.async {
              addPendingItem(image: image, suggestedLabel: "")
            }
          }
        case .failure:
          break
        }
      }
    }
    selectedPhotoItems = []
  }
  
  private func addPendingItem(image: UIImage, suggestedLabel: String) {
    let newItem = PendingItem(
      image: image,
      label: suggestedLabel.isEmpty ? "" : suggestedLabel
    )
    withAnimation {
      pendingItems.append(newItem)
    }
    if pendingItems.count == 1 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        focusedField = newItem.id
      }
    }
  }
  
  private func focusNextField(after currentId: UUID) {
    guard let currentIndex = pendingItems.firstIndex(where: { $0.id == currentId }) else {
      return
    }
    let nextIndex = currentIndex + 1
    if nextIndex < pendingItems.count {
      focusedField = pendingItems[nextIndex].id
    } else {
      focusedField = nil
    }
  }
  
  private func saveAllItems() {
    for item in pendingItems {
      let finalLabel = item.label.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !finalLabel.isEmpty else { continue }
      
      galleryStorage.addItem(image: item.image, label: finalLabel)
      
      let newChecklistItem = ChecklistItem(title: finalLabel, imageName: finalLabel)
      checklist.items.append(newChecklistItem)
    }
    
    var data = checklistService.checklistData
    if let index = data.checklists.firstIndex(where: { $0.id == checklist.id }) {
      data.checklists[index] = checklist
      checklistService.updateChecklistData(data)
    }
  }
}

struct GalleryMultiSelectView: View {
  @ObservedObject var galleryStorage: GalleryStorage
  var onSelect: ([GalleryItem]) -> Void
  @Environment(\.presentationMode) var presentationMode
  
  @State private var selectedItems: Set<UUID> = []
  
  private let columns = [
    GridItem(.adaptive(minimum: 100), spacing: 12)
  ]
  
  var body: some View {
    NavigationView {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(galleryStorage.items) { item in
            Button {
              if selectedItems.contains(item.id) {
                selectedItems.remove(item.id)
              } else {
                selectedItems.insert(item.id)
              }
            } label: {
              ZStack(alignment: .topTrailing) {
                if let image = item.image {
                  VStack(spacing: 4) {
                    Image(uiImage: image)
                      .resizable()
                      .scaledToFill()
                      .frame(width: 100, height: 100)
                      .clipShape(RoundedRectangle(cornerRadius: 10))
                      .overlay(
                        RoundedRectangle(cornerRadius: 10)
                          .stroke(
                            selectedItems.contains(item.id) ? Color.accentColor : Color.secondary.opacity(0.2),
                            lineWidth: selectedItems.contains(item.id) ? 3 : 1
                          )
                      )
                    
                    Text(item.label)
                      .font(.caption2)
                      .foregroundColor(.primary)
                      .lineLimit(1)
                  }
                }
                
                if selectedItems.contains(item.id) {
                  Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .background(
                      Circle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(width: 20, height: 20)
                    )
                    .offset(x: 4, y: -4)
                }
              }
            }
          }
        }
        .padding()
      }
      .navigationTitle(NSLocalizedString("Items", comment: ""))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(NSLocalizedString("Cancel", comment: "")) {
            presentationMode.wrappedValue.dismiss()
          }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(NSLocalizedString("Add", comment: "")) {
            let items = galleryStorage.items.filter { selectedItems.contains($0.id) }
            onSelect(items)
            presentationMode.wrappedValue.dismiss()
          }
          .fontWeight(.semibold)
          .disabled(selectedItems.isEmpty)
        }
      }
    }
  }
}

