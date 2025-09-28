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
    @State private var lastVibrationTime: Date = Date()
    
    @Environment(\.scenePhase) private var scenePhase
    
    private let vibrationManager = VibrationManager.shared
    private let minVibrationInterval: TimeInterval = 0.1
    
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
                                lastVibrationTime = Date() 
                            }
                            
                            let currentAngle = calculateAngle(from: centerPoint, to: value.location)
                            var angleDelta = currentAngle - lastAngle
                            
                    
                            if angleDelta > 180 {
                                angleDelta -= 360
                            } else if angleDelta < -180 {
                                angleDelta += 360
                            }
                            
                     
                            let newVelocity = max(-50, min(50, angleDelta * 4))
                            velocity = newVelocity
                            rotation += angleDelta
                            lastAngle = currentAngle
                            

                            let now = Date()
                            if abs(velocity) > 2.0 && now.timeIntervalSince(lastVibrationTime) > minVibrationInterval {
                                vibrationManager.triggerVelocityVibration(velocity: abs(velocity))
                                lastVibrationTime = now
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
                        let crownVelocity = crownDelta * 180 
                        

                        let limitedVelocity = max(-30, min(30, crownVelocity * 2))
                        velocity = limitedVelocity
                        rotation += crownVelocity
                        

                        let now = Date()
                        if abs(velocity) > 2.0 && now.timeIntervalSince(lastVibrationTime) > minVibrationInterval {
                            vibrationManager.triggerVelocityVibration(velocity: abs(velocity))
                            lastVibrationTime = now
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
        .onChange(of: scenePhase) { newPhase in

            if newPhase != .active {
                stopDeceleration()
            }
        }
    }
    
    private func startDeceleration() {
        stopDeceleration()
        
        if abs(velocity) > 1 {

            decelerationTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { timer in

                velocity *= 0.96
                rotation += velocity * 0.3
                
                if abs(velocity) < 0.5 {
                    timer.invalidate()
                    decelerationTimer = nil
                } else {

                    let now = Date()
                    if abs(velocity) > 3.0 && now.timeIntervalSince(lastVibrationTime) > minVibrationInterval * 2 {
                        vibrationManager.triggerVelocityVibration(velocity: abs(velocity))
                        lastVibrationTime = now
                    }
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
        

        guard abs(deltaX) > 0.001 || abs(deltaY) > 0.001 else {
            return 0
        }
        
        let angle = atan2(deltaY, deltaX) * (180 / Double.pi)
        

        if angle.isNaN || angle.isInfinite {
            return 0
        }
        
        return angle
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
