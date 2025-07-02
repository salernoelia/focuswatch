//
//  ChecklistCard.swift
//  fokusuhr-testing-platform
//
//  Created by Elia Salerno on 02.07.2025.
//


import SwiftUI

struct ChecklistCard<Item: ChecklistItem>: View {
    let item: Item
    let onAdd: () -> Void
    let onSkip: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var isProcessing = false
    
    private let dragThreshold: CGFloat = 40
    private let animationDuration: Double = 0.3
    
    var body: some View {
        VStack(spacing: 16) {
            Text(item.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .background(
            ZStack {
                Image(item.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 130)
                    .clipped()
                
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                
                Rectangle()
                    .fill(item.color.opacity(0.2))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: strokeWidth)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(x: dragOffset)
        .disabled(isProcessing)
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged(handleDragChange)
                .onEnded(handleDragEnd)
        )
    }
    
    private var borderColor: Color {
        if abs(dragOffset) < 20 { return .clear }
        return dragOffset > 0 ? .green : .orange
    }
    
    private var strokeWidth: CGFloat {
        abs(dragOffset) > 20 ? 3 : 0
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        guard !isProcessing else { return }
        
        let translation = value.translation.width
        
        if abs(translation) > abs(value.translation.height) {
            dragOffset = translation
            
            let progress = min(abs(translation) / 100, 1.0)
            scale = 1.0 - (progress * 0.1)
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        guard !isProcessing else { return }
        
        let translation = value.translation.width
        let velocity = value.velocity.width
        
        if abs(translation) > abs(value.translation.height) {
            if translation > dragThreshold || velocity > 300 {
                performAction(isAdd: true)
            } else if translation < -dragThreshold || velocity < -300 {
                performAction(isAdd: false)
            } else {
                resetCard()
            }
        } else {
            resetCard()
        }
    }
    
    private func performAction(isAdd: Bool) {
        isProcessing = true
        
        let targetOffset: CGFloat = isAdd ? 200 : -200
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            dragOffset = targetOffset
            scale = 0.8
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            if isAdd {
                onAdd()
            } else {
                onSkip()
            }
            resetState()
        }
    }
    
    private func resetCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func resetState() {
        dragOffset = 0
        scale = 1.0
        opacity = 1.0
        isProcessing = false
    }
}