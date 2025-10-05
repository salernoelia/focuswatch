import Foundation
import CoreGraphics

enum SpinnerPhysics {
    static let decelerationRate: Double = 0.96
    static let velocityMultiplier: Double = 0.3
    static let stopThreshold: Double = 0.5
    static let maxVelocity: Double = 50
    static let dragMultiplier: Double = 4
    static let crownRotationFactor: Double = 180
    static let crownVelocityMultiplier: Double = 2
    static let crownMaxVelocity: Double = 30
    static let minVibrationThreshold: Double = 2.0
    static let decelerationVibrationThreshold: Double = 3.0
    
    static func calculateAngle(from center: CGPoint, to point: CGPoint) -> Double {
        guard center != .zero else { return 0 }
        
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        
        guard abs(deltaX) > 0.001 || abs(deltaY) > 0.001 else {
            return 0
        }
        
        let angle = atan2(deltaY, deltaX) * (180 / Double.pi)
        
        guard !angle.isNaN && !angle.isInfinite else {
            return 0
        }
        
        return angle
    }
    
    static func normalizeAngleDelta(_ delta: Double) -> Double {
        var normalized = delta
        if normalized > 180 {
            normalized -= 360
        } else if normalized < -180 {
            normalized += 360
        }
        return normalized
    }
    
    static func constrainVelocity(_ velocity: Double, max: Double = maxVelocity) -> Double {
        return Swift.max(-max, Swift.min(max, velocity))
    }
}
