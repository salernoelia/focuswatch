//
//  GalleryItemCard.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 22.09.2025.
//


import SwiftUI
import PhotosUI

struct GalleryItemCard: View {
    let item: GalleryItem
    let size: CGFloat
    @State private var showingDeleteAlert = false
    @StateObject private var galleryStorage = GalleryStorage()
    
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
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Photo", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let index = galleryStorage.items.firstIndex(where: { $0.id == item.id }) {
                    galleryStorage.deleteItems(at: IndexSet([index]))
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(item.label)'?")
        }
    }
}