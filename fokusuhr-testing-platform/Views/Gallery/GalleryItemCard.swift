import PhotosUI
import SwiftUI

struct GalleryItemCard: View {
  let item: GalleryItem
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
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
          )
          .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
      } else {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.1))
          .frame(width: size, height: size)
          .overlay(
            Image(systemName: "photo")
              .foregroundColor(.secondary)
          )
      }

      Text(item.label)
        .font(.caption)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .frame(width: size)
        .foregroundColor(.primary)
    }
    .contentShape(Rectangle())
    .contextMenu {
      Button {
        editedLabel = item.label
        showingEditSheet = true
      } label: {
        Label("Edit Label", systemImage: "pencil")
      }

      Divider()

      Button(role: .destructive) {
        showingDeleteAlert = true
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
    .sheet(isPresented: $showingEditSheet) {
      NavigationView {
        Form {
          Section {
            if let image = item.image {
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
            TextField("Label", text: $editedLabel)
              .submitLabel(.done)
              .onSubmit {
                if !editedLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  galleryStorage.updateItemLabel(item, newLabel: editedLabel)
                  showingEditSheet = false
                }
              }
          } header: {
            Text("Label")
          } footer: {
            Text("Current: \(item.label)")
          }
        }
        .navigationTitle("Edit Photo")
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
            .fontWeight(.semibold)
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
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Are you sure you want to delete '\(item.label)'? This action cannot be undone.")
    }
  }
}
