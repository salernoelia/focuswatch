import SwiftUI
import WatchKit

struct FidgetSpinnerView: View {
    @State private var rotation: Double = 0
    @State private var velocity: Double = 0
    @State private var lastAngle: Double = 0
    @State private var isDragging = false
    @State private var centerPoint: CGPoint = .zero
    @State private var crownAccumulator: Double = 0
    @State private var lastCrownValue: Double = 0
    @State private var decelerationTimer: Timer?
    
    private let vibrationManager = VibrationManager.shared
    
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
                                vibrationManager.resetVibrationTiming()
                                stopDeceleration()
                            }
                            
                            let currentAngle = calculateAngle(from: centerPoint, to: value.location)
                            var angleDelta = currentAngle - lastAngle
                            
                            if angleDelta > 180 {
                                angleDelta -= 360
                            } else if angleDelta < -180 {
                                angleDelta += 360
                            }
                            
                            velocity = angleDelta * 4 
                            rotation += angleDelta
                            lastAngle = currentAngle
                            
                            // Trigger vibration directly based on velocity
                            if abs(velocity) > 0.5 {
                                vibrationManager.triggerVelocityVibration(velocity: abs(velocity))
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            startDeceleration()
                        }
                )
                .focusable(true)
                .digitalCrownRotation(
                    $crownAccumulator,
                    from: -Double.infinity,
                    through: Double.infinity,
                    by: 1.0,
                    sensitivity: .medium,
                    isContinuous: true,
                    isHapticFeedbackEnabled: false
                )
                .onChange(of: crownAccumulator) { newValue in
                    if !isDragging {
                        let crownDelta = newValue - lastCrownValue
                        let crownVelocity = crownDelta * 180 // Convert to degrees
                        
                        velocity = crownVelocity * 2
                        rotation += crownVelocity
                        
                        if abs(velocity) > 0.5 {
                            vibrationManager.triggerVelocityVibration(velocity: abs(velocity))
                            stopDeceleration()
                            startDeceleration()
                        }
                    }
                    lastCrownValue = newValue
                }
                .allowsHitTesting(true)
            }
        }
        .onDisappear {
            stopDeceleration()
        }
    }
    
    private func startDeceleration() {
        stopDeceleration()
        
        if abs(velocity) > 1 {
            decelerationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in // 60 FPS
                velocity *= 0.98
                rotation += velocity * 0.5
                
                if abs(velocity) < 0.5 {
                    timer.invalidate()
                    decelerationTimer = nil
                } else {
                    vibrationManager.triggerVelocityVibration(velocity: abs(velocity))
                }
            }
        }
    }
    
    private func stopDeceleration() {
        decelerationTimer?.invalidate()
        decelerationTimer = nil
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