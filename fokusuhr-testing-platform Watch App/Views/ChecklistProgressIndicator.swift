//
//  ChecklistProgressIndicator.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 02.07.2025.
//


import SwiftUI

struct ChecklistProgressIndicator: View {
    let totalItems: Int
    let collectedCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalItems, id: \.self) { index in
                Circle()
                    .fill(index < collectedCount ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(index < collectedCount ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: collectedCount)
            }
        }
    }
}