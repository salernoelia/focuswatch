import SwiftUI
import WatchKit

struct FidgetSpinnerView: View {
    @State private var rotation: Double = 0
    @State private var velocity: Double = 0
    @State private var isDragging = false
    @State private var lastAngle: Double = 0
    @State private var crownAccumulator: Double = 0
    @State private var lastCrownValue: Double = 0
    @State private var lastVibrationTime = Date()
    @State private var decelerationTask: Task<Void, Never>?
    
    @Environment(\.scenePhase) private var scenePhase
    
    private let minVibrationInterval: TimeInterval = 0.1
    private let spinnerSize: CGFloat = 120
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            spinnerWheel
                .rotationEffect(.degrees(rotation))
                .animation(isDragging ? nil : .easeOut(duration: abs(velocity) / 100), value: rotation)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged(handleDragChange)
                        .onEnded(handleDragEnd)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .digitalCrownRotation(
            $crownAccumulator,
            from: -Double.infinity,
            through: Double.infinity,
            by: 1.0,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownAccumulator, perform: handleCrownChange)
        .onChange(of: scenePhase, perform: handleScenePhaseChange)
        .onDisappear(perform: cleanup)
    }
    
    private var spinnerWheel: some View {
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
        .frame(width: spinnerSize, height: spinnerSize)
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        let center = CGPoint(x: spinnerSize / 2, y: spinnerSize / 2)
        
        if !isDragging {
            isDragging = true
            lastAngle = calculateAngle(from: center, to: value.location)
            stopDeceleration()
            lastVibrationTime = Date()
        }
        
        let currentAngle = calculateAngle(from: center, to: value.location)
        let angleDelta = normalizeAngleDelta(currentAngle - lastAngle)
        
        velocity = constrainVelocity(angleDelta * SpinnerPhysics.dragMultiplier)
        rotation += angleDelta
        lastAngle = currentAngle
        
        triggerVibrationIfNeeded()
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        isDragging = false
        startDeceleration()
    }
    
    private func handleCrownChange(_ newValue: Double) {
        guard !isDragging else { return }
        
        let crownDelta = newValue - lastCrownValue
        let crownVelocity = crownDelta * SpinnerPhysics.crownRotationFactor
        
        velocity = constrainVelocity(
            crownVelocity * SpinnerPhysics.crownVelocityMultiplier,
            max: SpinnerPhysics.crownMaxVelocity
        )
        rotation += crownVelocity
        lastCrownValue = newValue
        
        if triggerVibrationIfNeeded() {
            stopDeceleration()
            startDeceleration()
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        if phase != .active {
            cleanup()
        }
    }
    
    private func calculateAngle(from center: CGPoint, to point: CGPoint) -> Double {
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        
        guard abs(deltaX) > 0.001 || abs(deltaY) > 0.001 else {
            return 0
        }
        
        let angle = atan2(deltaY, deltaX) * (180 / Double.pi)
        return angle.isNaN || angle.isInfinite ? 0 : angle
    }
    
    private func normalizeAngleDelta(_ delta: Double) -> Double {
        var normalized = delta
        if normalized > 180 {
            normalized -= 360
        } else if normalized < -180 {
            normalized += 360
        }
        return normalized
    }
    
    private func constrainVelocity(_ velocity: Double, max: Double = SpinnerPhysics.maxVelocity) -> Double {
        return Swift.max(-max, Swift.min(max, velocity))
    }
    
    @discardableResult
    private func triggerVibrationIfNeeded() -> Bool {
        let now = Date()
        guard abs(velocity) > SpinnerPhysics.minVibrationThreshold,
              now.timeIntervalSince(lastVibrationTime) > minVibrationInterval else {
            return false
        }
        
        lastVibrationTime = now
        return true
    }
    
    private func startDeceleration() {
        stopDeceleration()
        
        guard abs(velocity) > 1 else { return }
        
        decelerationTask = Task {
            while !Task.isCancelled && abs(velocity) >= SpinnerPhysics.stopThreshold {
                try? await Task.sleep(nanoseconds: 33_000_000)
                
                guard !Task.isCancelled else { break }
                
                await MainActor.run {
                    velocity *= SpinnerPhysics.decelerationRate
                    rotation += velocity * SpinnerPhysics.velocityMultiplier
                    
                    let now = Date()
                    if abs(velocity) > SpinnerPhysics.decelerationVibrationThreshold,
                       now.timeIntervalSince(lastVibrationTime) > minVibrationInterval * 2 {
                        lastVibrationTime = now
                    }
                }
            }
        }
    }
    
    private func stopDeceleration() {
        decelerationTask?.cancel()
        decelerationTask = nil
    }
    
    private func cleanup() {
        stopDeceleration()
    }
}

#Preview {
    FidgetSpinnerView()
}