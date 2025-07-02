import WatchKit
import Foundation

class VibrationManager: ObservableObject {
    static let shared = VibrationManager()
    
    private var vibrationTimer: Timer?
    private var currentIntensity: Double = 0
    
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
    
    
    func startProgressiveVibration(velocity: Double) {
        guard velocity > 1 else { 
            stopProgressiveVibration()
            return 
        }
        
        let normalizedVelocity = min(abs(velocity), 100)
        currentIntensity = normalizedVelocity
        
        if vibrationTimer == nil {
            let baseInterval = 0.015 
            let interval = max(0.008, baseInterval - (normalizedVelocity / 100) * 0.007) 
            
            vibrationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.triggerVelocityBasedVibration()
            }
        }
    }
    
    func stopProgressiveVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        currentIntensity = 0
    }
    
    func updateProgressiveVibration(velocity: Double) {
        guard velocity > 1 else { 
            stopProgressiveVibration()
            return
        }
        
        let normalizedVelocity = min(abs(velocity), 100)
        currentIntensity = normalizedVelocity
    }
    
    
    private func triggerVelocityBasedVibration() {
        let intensity = currentIntensity / 100
        
        switch intensity {
        case 0.0..<0.3:
            WKInterfaceDevice.current().play(.start)
        case 0.3..<0.6:
            WKInterfaceDevice.current().play(.stop)
        case 0.6..<0.8:
            WKInterfaceDevice.current().play(.retry)
        default:
            WKInterfaceDevice.current().play(.retry)
        }
    }
}