import Foundation
import AppKit
import ApplicationServices

public final class AccessibilityManager {
    public static let shared = AccessibilityManager()
    
    private init() {}
    
    public var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }
    
    public func checkAndPromptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        if !isTrusted {
            print("[Klack AccessibilityManager] Prompting for Accessibility permission.")
        }
    }
    
    public func openAccessibilityPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
