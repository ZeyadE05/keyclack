import Foundation
import AppKit

public final class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    private var toggleMuteMenuItem: NSMenuItem!
    private var accessibilityMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!
    private var profileMenuItems: [SoundProfile: NSMenuItem] = [:]
    private var volumeSlider: NSSlider!
    private var volumeLabel: NSTextField!
    
    private var permissionCheckTimer: Timer?
    
    public override init() {
        super.init()
        setupStatusItem()
        setupMenu()
        startPermissionMonitoring()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                button.image = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: "KeyClack Keyboard Sounds")?
                    .withSymbolConfiguration(config)
            } else {
                button.title = "⌨️ KeyClack"
            }
            button.toolTip = "KeyClack - Mechanical Keyboard Sounds"
        }
    }
    
    private func setupMenu() {
        menu = NSMenu(title: "KeyClack")
        menu.delegate = self
        
        // 1. Header / Status
        let headerItem = NSMenuItem(title: "KeyClack Mechanical Audio", action: nil, keyEquivalent: "")
        let headerFont = NSFont.boldSystemFont(ofSize: 13)
        headerItem.attributedTitle = NSAttributedString(string: "KeyClack Audio Engine", attributes: [.font: headerFont])
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Toggle Sound Mute
        toggleMuteMenuItem = NSMenuItem(title: "Sound Enabled", action: #selector(toggleMutePressed), keyEquivalent: "s")
        toggleMuteMenuItem.target = self
        toggleMuteMenuItem.state = SoundEngine.shared.isMuted ? .off : .on
        menu.addItem(toggleMuteMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Volume Slider Custom View
        let volumeViewItem = NSMenuItem()
        volumeViewItem.view = createVolumeSliderView()
        menu.addItem(volumeViewItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Sound Profile Submenu
        let profileSubmenu = NSMenu(title: "Sound Profile")
        for profile in SoundProfile.allCases {
            let item = NSMenuItem(title: profile.rawValue, action: #selector(profileSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = profile
            if profile == SoundEngine.shared.currentProfile {
                item.state = .on
            }
            profileMenuItems[profile] = item
            profileSubmenu.addItem(item)
        }
        
        let profileParentItem = NSMenuItem(title: "Sound Profile", action: nil, keyEquivalent: "")
        profileParentItem.submenu = profileSubmenu
        menu.addItem(profileParentItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. Accessibility Status & Fix Button
        accessibilityMenuItem = NSMenuItem(title: "Accessibility: Checking...", action: #selector(accessibilityActionPressed), keyEquivalent: "")
        accessibilityMenuItem.target = self
        menu.addItem(accessibilityMenuItem)
        
        // 6. Launch at Login
        launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(launchAtLoginMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 7. Quit Application
        let quitItem = NSMenuItem(title: "Quit KeyClack", action: #selector(quitPressed), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        updateAccessibilityStatus()
    }
    
    private func createVolumeSliderView() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 36))
        
        let titleLabel = NSTextField(labelWithString: "Volume")
        titleLabel.frame = NSRect(x: 18, y: 10, width: 55, height: 16)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .labelColor
        container.addSubview(titleLabel)
        
        volumeSlider = NSSlider(value: Double(SoundEngine.shared.volume), minValue: 0.0, maxValue: 1.0, target: self, action: #selector(volumeSliderChanged(_:)))
        volumeSlider.frame = NSRect(x: 75, y: 8, width: 95, height: 20)
        volumeSlider.isContinuous = true
        container.addSubview(volumeSlider)
        
        let initialPercent = Int(SoundEngine.shared.volume * 100)
        volumeLabel = NSTextField(labelWithString: "\(initialPercent)%")
        volumeLabel.frame = NSRect(x: 175, y: 10, width: 38, height: 16)
        volumeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        volumeLabel.textColor = .secondaryLabelColor
        container.addSubview(volumeLabel)
        
        return container
    }
    
    @objc private func volumeSliderChanged(_ sender: NSSlider) {
        let newVolume = Float(sender.doubleValue)
        SoundEngine.shared.volume = newVolume
        let percent = Int(newVolume * 100)
        volumeLabel.stringValue = "\(percent)%"
        
        if newVolume > 0 && SoundEngine.shared.isMuted {
            SoundEngine.shared.isMuted = false
            toggleMuteMenuItem.state = .on
        }
    }
    
    @objc private func toggleMutePressed() {
        SoundEngine.shared.isMuted.toggle()
        toggleMuteMenuItem.state = SoundEngine.shared.isMuted ? .off : .on
    }
    
    @objc private func profileSelected(_ sender: NSMenuItem) {
        guard let profile = sender.representedObject as? SoundProfile else { return }
        
        SoundEngine.shared.loadProfile(profile)
        for (prof, item) in profileMenuItems {
            item.state = (prof == profile) ? .on : .off
        }
        
        // Play quick preview sample
        SoundEngine.shared.playSound(category: .keyDown)
    }
    
    @objc private func accessibilityActionPressed() {
        if !AccessibilityManager.shared.isAccessibilityGranted {
            AccessibilityManager.shared.openAccessibilityPrivacySettings()
            AccessibilityManager.shared.checkAndPromptAccessibilityPermission()
        }
    }
    
    @objc private func toggleLaunchAtLogin() {
        let current = LaunchAtLoginManager.shared.isEnabled
        LaunchAtLoginManager.shared.isEnabled = !current
        launchAtLoginMenuItem.state = !current ? .on : .off
    }
    
    @objc private func quitPressed() {
        NSApplication.shared.terminate(nil)
    }
    
    private func updateAccessibilityStatus() {
        let isGranted = AccessibilityManager.shared.isAccessibilityGranted
        if isGranted {
            accessibilityMenuItem.title = "Accessibility: Granted ✓"
            accessibilityMenuItem.action = nil
            accessibilityMenuItem.image = nil
            
            // Start event tap if not already active
            if !EventTapManager.shared.isRunning {
                EventTapManager.shared.start()
            }
        } else {
            accessibilityMenuItem.title = "Accessibility: Required (Click to Fix)"
            accessibilityMenuItem.action = #selector(accessibilityActionPressed)
        }
    }
    
    private func startPermissionMonitoring() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateAccessibilityStatus()
            }
        }
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        updateAccessibilityStatus()
        toggleMuteMenuItem.state = SoundEngine.shared.isMuted ? .off : .on
        volumeSlider.doubleValue = Double(SoundEngine.shared.volume)
        volumeLabel.stringValue = "\(Int(SoundEngine.shared.volume * 100))%"
        launchAtLoginMenuItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
    }
}
