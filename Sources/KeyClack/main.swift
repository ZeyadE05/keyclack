import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[KeyClack] Initializing KeyClack Menu Bar Agent...")
        
        // Force accessory activation policy (no dock icon, menu bar agent)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize Menu Bar UI
        menuBarController = MenuBarController()
        
        // Initialize Sound Engine
        _ = SoundEngine.shared
        
        // Check Accessibility Permissions & Start Keystroke Tap
        if AccessibilityManager.shared.isAccessibilityGranted {
            EventTapManager.shared.start()
        } else {
            print("[KeyClack] Accessibility permissions missing on startup. Prompting user...")
            AccessibilityManager.shared.checkAndPromptAccessibilityPermission()
        }
        
        print("[KeyClack] Application launch complete.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("[KeyClack] Terminating KeyClack...")
        EventTapManager.shared.stop()
    }
}

// Global App Initialization
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
