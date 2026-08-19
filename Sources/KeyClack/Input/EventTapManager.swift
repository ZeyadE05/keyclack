import Foundation
import CoreGraphics
import ApplicationServices

public final class EventTapManager {
    public static let shared = EventTapManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    public private(set) var isRunning: Bool = false
    
    private init() {}
    
    private let eventCallback: CGEventTapCallBack = { proxy, type, event, refcon in
        guard let refcon = refcon else {
            return Unmanaged.passUnretained(event)
        }
        
        let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
        return manager.handleEvent(proxy: proxy, type: type, event: event)
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("[KeyClack EventTap] Tap disabled by system (timeout/load). Auto-recovering...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }
        
        // Filter out key repeats to prevent sound flutter during holds
        if type == .keyDown {
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if isRepeat {
                return Unmanaged.passUnretained(event)
            }
        }
        
        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        let category = resolveCategory(keycode: keycode, isKeyDown: type == .keyDown)
        
        // Trigger low-latency audio playback
        SoundEngine.shared.playSound(category: category)
        
        return Unmanaged.passUnretained(event)
    }
    
    private func resolveCategory(keycode: Int64, isKeyDown: Bool) -> SoundCategory {
        switch keycode {
        case 49: // Spacebar
            return isKeyDown ? .spaceDown : .spaceUp
        case 36, 76: // Return / Numpad Enter
            return isKeyDown ? .enterDown : .enterUp
        case 51, 117: // Delete / Forward Delete
            return isKeyDown ? .backspaceDown : .backspaceUp
        default: // Standard key
            return isKeyDown ? .keyDown : .keyUp
        }
    }
    
    @discardableResult
    public func start() -> Bool {
        guard !isRunning else { return true }
        
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: eventCallback,
            userInfo: selfPtr
        ) else {
            print("[KeyClack EventTap] Failed to create event tap. Accessibility permission needed.")
            return false
        }
        
        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            isRunning = true
            print("[KeyClack EventTap] Global keystroke tap active.")
            return true
        }
        
        return false
    }
    
    public func stop() {
        guard isRunning, let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        print("[KeyClack EventTap] Global keystroke tap stopped.")
    }
}
