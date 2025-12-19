import SwiftUI
import WatchKit

class ColorBreathingViewModel: ObservableObject {
    @Published var scale: CGFloat = 0.5
    @Published var isInhaling: Bool = true
    @Published var configuration = ColorBreathingConfiguration()
    @Published var currentCycle: Int = 0

    private var timer: Timer?
    private var isActive = false

    init() {
        loadConfiguration()
        setupConfigurationObserver()
    }

    private func loadConfiguration() {
        let configurations = SyncCoordinator.loadAppConfigurations()
        configuration = configurations.colorBreathing
    }

    private func setupConfigurationObserver() {
        NotificationCenter.default.addObserver(
            forName: .appConfigurationsUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let configurations = notification.object as? AppConfigurations
            else { return }

            self.configuration = configurations.colorBreathing
        }
    }

    func startBreathing() {
        guard !isActive else { return }
        isActive = true
        
        scale = 0.5
        isInhaling = true
        currentCycle = 1
        
        if configuration.vibrationOnTransition {
            vibrate()
        }
        
        withAnimation(.easeInOut(duration: Double(configuration.inhaleSeconds))) {
            scale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(configuration.inhaleSeconds)) { [weak self] in
            self?.transitionToExhale()
        }
    }
    
    private func transitionToExhale() {
        guard isActive else { return }
        
        isInhaling = false
        
        if configuration.vibrationOnTransition {
            vibrate()
        }
        
        withAnimation(.easeInOut(duration: Double(configuration.exhaleSeconds))) {
            scale = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(configuration.exhaleSeconds)) { [weak self] in
            self?.completeBreathCycle()
        }
    }
    
    private func completeBreathCycle() {
        guard isActive else { return }
        
        if currentCycle >= configuration.cycleCount {
            restartBreathing()
            return
        }
        
        currentCycle += 1
        isInhaling = true
        
        if configuration.vibrationOnTransition {
            vibrate()
        }
        
        withAnimation(.easeInOut(duration: Double(configuration.inhaleSeconds))) {
            scale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(configuration.inhaleSeconds)) { [weak self] in
            self?.transitionToExhale()
        }
    }
    
    private func restartBreathing() {
        isActive = false
        scale = 0.5
        isInhaling = true
        currentCycle = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startBreathing()
        }
    }

    func stopBreathing() {
        isActive = false
        timer?.invalidate()
        timer = nil
        scale = 0.5
        isInhaling = true
        currentCycle = 0
    }

    private func vibrate() {
        WKInterfaceDevice.current().play(configuration.vibrationIntensity.hapticType)
    }
}
