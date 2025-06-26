import SwiftUI
import WatchKit

struct FidgetSpinnerView: View {
    @State private var rotation: Double = 0
    @State private var velocity: Double = 0
    @State private var lastAngle: Double = 0
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            SpinnerWheel(rotation: rotation)
                .rotationEffect(.degrees(rotation))
                .animation(.interpolatingSpring(stiffness: 50, damping: 8), value: isDragging ? 0 : rotation)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                lastAngle = atan2(value.location.y - 60, value.location.x - 60) * (180 / Double.pi)
                            }
                            
                            let currentAngle = atan2(value.location.y - 60, value.location.x - 60) * (180 / Double.pi)
                            let angleDelta = currentAngle - lastAngle
                            
                            if abs(angleDelta) < 180 {
                                velocity = angleDelta * 0.5
                                rotation += angleDelta
                            }
                            
                            lastAngle = currentAngle
                            
                            let vibrationIntensity = abs(velocity) / 5
                            if vibrationIntensity > 0.5 {
                                WKInterfaceDevice.current().play(.click)
                            } else if vibrationIntensity > 0.2 {
                                WKInterfaceDevice.current().play(.start)
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            
                            withAnimation(.easeOut(duration: 2)) {
                                rotation += velocity * 20
                                velocity = 0
                            }
                        }
                )
        }
    }
}

struct SpinnerWheel: View {
    let rotation: Double
    
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                    .offset(y: -50)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            Circle()
                .fill(Color.gray)
                .frame(width: 14, height: 14)
        }
        .frame(width: 170, height: 170)
    }
}

#Preview {
    FidgetSpinnerView()
}
