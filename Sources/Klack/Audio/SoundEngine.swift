import Foundation
import AVFoundation

public final class SoundEngine {
    public static let shared = SoundEngine()
    
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    
    private let poolSize = 12
    private var playerPool: [AVAudioPlayerNode] = []
    private var poolIndex = 0
    
    private var soundBuffers: [SoundCategory: AVAudioPCMBuffer] = [:]
    
    public private(set) var currentProfile: SoundProfile = .cherryMXBlue
    public var isMuted: Bool = false {
        didSet {
            mixer.outputVolume = isMuted ? 0.0 : volume
        }
    }
    
    public var volume: Float = 0.8 {
        didSet {
            if !isMuted {
                mixer.outputVolume = volume
            }
        }
    }
    
    private init() {
        setupAudioEngine()
        loadProfile(currentProfile)
    }
    
    private func setupAudioEngine() {
        engine.attach(mixer)
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)
        
        // Create active round-robin player pool
        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: format)
            playerPool.append(player)
        }
        
        mixer.outputVolume = volume
        
        do {
            try engine.start()
            print("[Klack SoundEngine] Audio Engine started successfully.")
        } catch {
            print("[Klack SoundEngine] Error starting engine: \(error.localizedDescription)")
        }
    }
    
    public func loadProfile(_ profile: SoundProfile) {
        currentProfile = profile
        let format = engine.outputNode.outputFormat(forBus: 0)
        
        // First check if custom wav files exist in user config directory ~/.config/klack/sounds/<profile>/
        let customBuffers = loadCustomWavBuffers(for: profile, format: format)
        
        if !customBuffers.isEmpty {
            soundBuffers = customBuffers
            print("[Klack SoundEngine] Loaded custom WAV buffers for \(profile.rawValue)")
        } else {
            // Synthesize high-fidelity procedural PCM buffers in memory
            soundBuffers = ProceduralSynthesizer.generateBufferSet(for: profile, format: format)
            print("[Klack SoundEngine] Synthesized procedural buffers for \(profile.rawValue)")
        }
    }
    
    private func loadCustomWavBuffers(for profile: SoundProfile, format: AVAudioFormat) -> [SoundCategory: AVAudioPCMBuffer] {
        var buffers: [SoundCategory: AVAudioPCMBuffer] = [:]
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let profileDir = home.appendingPathComponent(".config/klack/sounds/\(profile.rawValue)")
        
        for category in SoundCategory.allCases {
            let fileURL = profileDir.appendingPathComponent("\(category.rawValue).wav")
            if fileManager.fileExists(atPath: fileURL.path),
               let file = try? AVAudioFile(forReading: fileURL),
               let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) {
                do {
                    try file.read(into: buffer)
                    buffers[category] = buffer
                } catch {
                    print("[Klack SoundEngine] Could not read \(fileURL.path): \(error)")
                }
            }
        }
        return buffers
    }
    
    public func playSound(category: SoundCategory) {
        guard !isMuted, volume > 0.0 else { return }
        
        guard let buffer = soundBuffers[category] else {
            // Fallback to keyDown if category sound is missing
            if let fallback = soundBuffers[.keyDown] {
                playBuffer(fallback)
            }
            return
        }
        
        playBuffer(buffer)
    }
    
    private func playBuffer(_ buffer: AVAudioPCMBuffer) {
        // Ensure engine is running
        if !engine.isRunning {
            try? engine.start()
        }
        
        let player = playerPool[poolIndex]
        poolIndex = (poolIndex + 1) % poolSize
        
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
}
