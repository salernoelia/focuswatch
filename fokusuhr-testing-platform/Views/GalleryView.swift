//
//  GalleryView.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 21.08.2025.
//

import SwiftUI
import PhotosUI

struct GalleryView: View {
    @StateObject private var storage = GalleryStorage()
    @State private var showingPicker = false
    @State private var pickedImage: UIImage?
    @State private var newLabel = ""
    @State private var showingLabelSheet = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(storage.items) { item in
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
                }
                .padding()
            }
            .navigationTitle("Gallery")
            .toolbar {
                Button(action: { showingPicker = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingPicker) {
                PhotoPicker { images in
                    if let first = images.first {
                        pickedImage = first
                        newLabel = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingLabelSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { showingLabelSheet && pickedImage != nil },
                set: { showingLabelSheet = $0 }
            )) {
                if let uiImage = pickedImage {
                    let content = VStack(spacing: 16) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)

                        TextField("Enter label", text: $newLabel)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        HStack {
                            Button("Cancel") {
                                showingLabelSheet = false
                            }
                            Spacer()
                            Button("Save") {
                                storage.addItem(image: uiImage, label: newLabel)
                                showingLabelSheet = false
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }.padding(.top)
                    
                    if #available(iOS 16.0, *) {
                        content
                            .presentationDetents([.fraction(0.4)])
                    } else {
                        content
                    }
                }
                    
            }
        }
    }
}


struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
    }
}
