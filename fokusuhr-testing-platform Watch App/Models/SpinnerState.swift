import Foundation

struct SpinnerState {
    var rotation: Double = 0
    var velocity: Double = 0
    var lastAngle: Double = 0
    var isDragging = false
    var centerPoint: CGPoint = .zero
    var crownAccumulator: Double = 0
    var lastCrownValue: Double = 0
    var lastVibrationTime: Date = Date()
    
    mutating func reset() {
        rotation = 0
        velocity = 0
        lastAngle = 0
        isDragging = false
        centerPoint = .zero
        crownAccumulator = 0
        lastCrownValue = 0
        lastVibrationTime = Date()
    }
}
