import Foundation
import ServiceManagement

public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()
    
    private init() {}
    
    public var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
            }
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                        print("[Klack AutoStart] Enabled launch at login via SMAppService.")
                    } else {
                        try SMAppService.mainApp.unregister()
                        print("[Klack AutoStart] Disabled launch at login via SMAppService.")
                    }
                } catch {
                    print("[Klack AutoStart] Failed to update launch at login status: \(error)")
                }
            } else {
                UserDefaults.standard.set(newValue, forKey: "LaunchAtLogin")
            }
        }
    }
}
