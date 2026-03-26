import SwiftUI

struct ImageSelectorView: View {
  let currentImageName: String
  @ObservedObject var galleryStorage: GalleryStorage
  var onSelect: (String) -> Void
  @Environment(\.presentationMode) var presentationMode
  
  private let columns = [
    GridItem(.adaptive(minimum: 90), spacing: 12)
  ]
  
  var body: some View {
    NavigationView {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 12) {
          Button {
            onSelect("")
            presentationMode.wrappedValue.dismiss()
          } label: {
            VStack(spacing: 4) {
              RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 90, height: 90)
                .overlay(
                  Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 10)
                    .stroke(
                      currentImageName.isEmpty ? Color.accentColor : Color.secondary.opacity(0.2),
                      lineWidth: currentImageName.isEmpty ? 3 : 1
                    )
                )
              
              Text(NSLocalizedString("None", comment: ""))
                .font(.caption2)
                .foregroundColor(.primary)
            }
          }
          
          ForEach(galleryStorage.items) { item in
            Button {
              onSelect(item.label)
              presentationMode.wrappedValue.dismiss()
            } label: {
              if let image = item.image {
                VStack(spacing: 4) {
                  Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                      RoundedRectangle(cornerRadius: 10)
                        .stroke(
                          currentImageName == item.label ? Color.accentColor : Color.secondary.opacity(0.2),
                          lineWidth: currentImageName == item.label ? 3 : 1
                        )
                    )
                  
                  Text(item.label)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                }
              }
            }
          }
        }
        .padding()
      }
      .navigationTitle(NSLocalizedString("Choose Image", comment: ""))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(NSLocalizedString("Done", comment: "")) {
            presentationMode.wrappedValue.dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }
}

