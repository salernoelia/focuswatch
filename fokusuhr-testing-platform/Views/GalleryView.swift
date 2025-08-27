//
//  GalleryView.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 21.08.2025.
//

import SwiftUI
import PhotosUI

struct GalleryView: View {
    @StateObject private var galleryStorage = GalleryStorage()
    @State private var showingPhotoPicker = false
    @State private var showingCameraPicker = false
    @State private var showingActionSheet = false
    @State private var newImageLabel = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showingLabelInput = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(galleryStorage.items) { item in
                        VStack {
                            if let image = item.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                            Text(item.label)
                                .font(.caption)
                                .lineLimit(1)
                    }
                }
                .onDelete(perform: galleryStorage.deleteItems)
            }
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                    showingLabelInput = true
                }
            }
            .sheet(isPresented: $showingCameraPicker) {
                PhotoPicker(source: .camera) { images in
                    selectedImages = images
                    showingLabelInput = true
                }
            }
            .alert("Add Label", isPresented: $showingLabelInput) {
                TextField("Enter label", text: $newImageLabel)
                Button("Add") {
                    if let image = selectedImages.first, !newImageLabel.isEmpty {
                        galleryStorage.addItem(image: image, label: newImageLabel)
                        newImageLabel = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    newImageLabel = ""
                }
            }
        }
    }
}
