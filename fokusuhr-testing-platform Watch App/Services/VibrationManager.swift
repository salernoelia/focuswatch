import WatchKit
import Foundation

class VibrationManager: ObservableObject {
    static let shared = VibrationManager()
    
    private var lastVibrationTime: TimeInterval = 0
    private var vibrationFrameCounter: Int = 0
    
    private init() {}
    
    func lightVibration() {
        WKInterfaceDevice.current().play(.click)
    }
    
    func mediumVibration() {
        WKInterfaceDevice.current().play(.notification)
    }
    
    func strongVibration() {
        WKInterfaceDevice.current().play(.directionUp)
    }
    
    func customVibration(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
    
    func triggerVelocityVibration(velocity: Double) {
        let currentTime = Date().timeIntervalSince1970
        let normalizedVelocity = min(abs(velocity), 100)
        

        let minInterval: TimeInterval = 0.02
        let maxInterval: TimeInterval = 0.1
        let velocityFactor = normalizedVelocity / 100
        let targetInterval = maxInterval - (velocityFactor * (maxInterval - minInterval))
        
        guard currentTime - lastVibrationTime >= targetInterval else { return }
        
        lastVibrationTime = currentTime
        

        vibrationFrameCounter += 1
        let frameSkip = max(1, Int(4 - (velocityFactor * 3)))
        
        guard vibrationFrameCounter % frameSkip == 0 else { return }
        
        let intensity = normalizedVelocity / 100
        
        switch intensity {
        case 0.0..<0.2:
            WKInterfaceDevice.current().play(.click)
        case 0.2..<0.5:
            WKInterfaceDevice.current().play(.start)
        case 0.5..<0.8:
            WKInterfaceDevice.current().play(.stop)
        default:
            WKInterfaceDevice.current().play(.retry)
        }
    }
    
    func resetVibrationTiming() {
        lastVibrationTime = 0
        vibrationFrameCounter = 0
    }
}

