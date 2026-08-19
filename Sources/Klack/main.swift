import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[Klack] Initializing Klack Menu Bar Agent...")
        
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
            print("[Klack] Accessibility permissions missing on startup. Prompting user...")
            AccessibilityManager.shared.checkAndPromptAccessibilityPermission()
        }
        
        print("[Klack] Application launch complete.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("[Klack] Terminating Klack...")
        EventTapManager.shared.stop()
    }
}

// Global App Initialization
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
