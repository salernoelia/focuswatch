import SwiftUI

struct SettingsView: View {
    @State private var watchId: String = ""
    @State private var appVersion: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(String(localized: "Watch ID"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(watchId)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 8) {
                    Text(String(localized: "App Version"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(appVersion)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
               
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .navigationTitle(String(localized: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadWatchInfo()
        }
    }
    
    private func loadWatchInfo() {
        let fullUUID = WatchConfig.shared.uuid
        watchId = String(fullUUID.prefix(8)).uppercased()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        } else {
            appVersion = "Unknown"
        }
        
        updateWidgetData()
    }
    
    private func updateWidgetData() {
        let sharedDefaults = UserDefaults(suiteName: "group.net.com.fokusuhr")
        let fullUUID = WatchConfig.shared.uuid
        sharedDefaults?.set(fullUUID, forKey: "deviceUUID")
        sharedDefaults?.synchronize()
        
#if DEBUG
        print("⌚ SettingsView: Updated widget data - UUID: \(String(fullUUID.prefix(8)))")
#endif
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
