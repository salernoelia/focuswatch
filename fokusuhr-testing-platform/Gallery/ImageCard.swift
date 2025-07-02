//
//  ImageCard.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 02.07.2025.
//

import SwiftUI
import UIKit

struct ImageCard: View {
    let imageName: String
    let isBuiltIn: Bool
    let onDelete: (() -> Void)?
    let onRename: ((String) -> Void)?
    let displayNameMapping: [String: String]
    
    @State private var showingRenameAlert = false
    @State private var newName = ""
    
    init(imageName: String, isBuiltIn: Bool, onDelete: (() -> Void)?, onRename: ((String) -> Void)? = nil, displayNameMapping: [String: String] = [:]) {
        self.imageName = imageName
        self.isBuiltIn = isBuiltIn
        self.onDelete = onDelete
        self.onRename = onRename
        self.displayNameMapping = displayNameMapping
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if isBuiltIn {
                    SafeImage(imageName: imageName)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                } else {
                    if let image = ImageManager.shared.loadImage(named: imageName) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                    }
                }
                
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .offset(x: 5, y: -5)
                }
            }
            
            if isBuiltIn {
                Text(imageName)
                    .font(.caption2)
                    .lineLimit(1)
            } else {
                Button(displayName) {
                    newName = displayName
                    showingRenameAlert = true
                }
                .font(.caption2)
                .foregroundColor(.blue)
                .lineLimit(1)
            }
        }
        .frame(width: 100, height: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .alert("Rename Image", isPresented: $showingRenameAlert) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let onRename = onRename, !newName.isEmpty {
                    onRename(newName)
                }
            }
        }
    }
    
    private var displayName: String {
        if let customName = displayNameMapping[imageName] {
            return customName
        }
        if imageName.hasPrefix("custom_") {
            return "Custom Image"
        }
        return imageName
    }
}