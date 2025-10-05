import SwiftUI
import PhotosUI

struct GalleryItemCard: View {
    let item: GalleryItemModel
    let size: CGFloat
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var editedLabel = ""
    @ObservedObject var galleryStorage: GalleryStorage
    
   var body: some View {
        VStack(spacing: 8) {
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(item.label)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: size)
        }
       .contextMenu {
            Button {
                editedLabel = item.label
                showingEditSheet = true
            } label: {
                Label("Edit Label", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                VStack(spacing: 24) {
                    if let image = item.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Edit photo label:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter new label", text: $editedLabel)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                            .submitLabel(.done)
                            .onSubmit {
                                if !editedLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    galleryStorage.updateItemLabel(item, newLabel: editedLabel)
                                    showingEditSheet = false
                                }
                            }
                        
                        Text("Current: \(item.label)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(20)
                .navigationTitle("Edit Label")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            editedLabel = item.label
                            showingEditSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            if !editedLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                galleryStorage.updateItemLabel(item, newLabel: editedLabel)
                                showingEditSheet = false
                            }
                        }
               
                        .disabled(editedLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onAppear {
                editedLabel = item.label
            }
        }
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                galleryStorage.deleteItem(item)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(item.label)'? This action cannot be undone.")
        }
    }
}
