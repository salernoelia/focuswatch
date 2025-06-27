import SwiftUI
import WatchKit

struct FidgetSpinnerView: View {
    @State private var rotation: Double = 0
    @State private var velocity: Double = 0
    @State private var lastAngle: Double = 0
    @State private var isDragging = false
    @State private var centerPoint: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 120, height: 120)
                        .contentShape(Circle())
                    
                    SpinnerWheel()
                }
                .rotationEffect(.degrees(rotation))
                .animation(isDragging ? nil : .easeOut(duration: abs(velocity) / 100), value: rotation)
                .gesture(
                    DragGesture(coordinateSpace: .local)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                centerPoint = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                lastAngle = calculateAngle(from: centerPoint, to: value.location)
                            }
                            
                            let currentAngle = calculateAngle(from: centerPoint, to: value.location)
                            var angleDelta = currentAngle - lastAngle
                            
                            if angleDelta > 180 {
                                angleDelta -= 360
                            } else if angleDelta < -180 {
                                angleDelta += 360
                            }
                            
                            velocity = angleDelta * 2
                            rotation += angleDelta
                            lastAngle = currentAngle
                            
                            if abs(velocity) > 5 {
                                WKInterfaceDevice.current().play(.click)
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            
                            let finalRotation = rotation + velocity * 10
                            withAnimation(.easeOut(duration: min(abs(velocity) / 50, 3))) {
                                rotation = finalRotation
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                velocity *= 0.95
                            }
                        }
                )
            }
        }
    }
    
    private func calculateAngle(from center: CGPoint, to point: CGPoint) -> Double {
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        return atan2(deltaY, deltaX) * (180 / Double.pi)
    }
}

struct SpinnerWheel: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(y: -45)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            Circle()
                .fill(Color.gray)
                .frame(width: 16, height: 16)
        }
        .frame(width: 120, height: 120)
    }
}

#Preview {
    FidgetSpinnerView()
}
