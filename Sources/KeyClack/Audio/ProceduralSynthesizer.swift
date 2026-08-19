import Foundation
import AVFoundation

public enum SoundCategory: String, Hashable, CaseIterable {
    case keyDown
    case keyUp
    case spaceDown
    case spaceUp
    case backspaceDown
    case backspaceUp
    case enterDown
    case enterUp
}

public enum SoundProfile: String, CaseIterable, Identifiable {
    case cherryMXBlue = "Cherry MX Blue (Clicky)"
    case alpacaLinear = "Alpaca Linear (Thock)"
    case topreTactile = "Topre (Tactile Pop)"
    case holyPanda = "Holy Panda (Tactile Snap)"
    case ibmModelM = "IBM Model M (Buckling Spring)"
    case novelKeysCream = "NovelKeys Cream (Marbly)"
    case typewriter = "Retro Typewriter (Cast Iron)"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .cherryMXBlue: return "bolt.fill"
        case .alpacaLinear: return "wave.3.forward.circle.fill"
        case .topreTactile: return "circle.hexagongrid.fill"
        case .holyPanda: return "sparkles"
        case .ibmModelM: return "bell.fill"
        case .novelKeysCream: return "drop.fill"
        case .typewriter: return "keyboard"
        }
    }
}

public final class ProceduralSynthesizer {
    
    public static func generateBufferSet(for profile: SoundProfile, format: AVAudioFormat) -> [SoundCategory: AVAudioPCMBuffer] {
        var buffers: [SoundCategory: AVAudioPCMBuffer] = [:]
        
        for category in SoundCategory.allCases {
            if let buffer = generateBuffer(profile: profile, category: category, format: format) {
                buffers[category] = buffer
            }
        }
        
        return buffers
    }
    
    private static func generateBuffer(profile: SoundProfile, category: SoundCategory, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = Float(format.sampleRate)
        guard sampleRate > 0 else { return nil }
        
        // Duration in seconds for each sound
        let duration: Float = {
            switch profile {
            case .typewriter, .ibmModelM:
                switch category {
                case .spaceDown, .spaceUp, .enterDown, .enterUp: return 0.070
                default: return 0.050
                }
            default:
                switch category {
                case .spaceDown, .spaceUp: return 0.055
                case .enterDown, .enterUp: return 0.045
                case .backspaceDown, .backspaceUp: return 0.040
                default: return 0.035
                }
            }
        }()
        
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        pcmBuffer.frameLength = frameCount
        
        let channels = Int(format.channelCount)
        let floatBuffers = pcmBuffer.floatChannelData
        
        // Random seed generator for white noise bursts
        var seed: UInt32 = UInt32(category.hashValue & 0x7FFFFFFF) + 100
        func randomNoise() -> Float {
            seed = seed &* 1664525 &+ 1013904223
            return (Float(seed) / Float(UInt32.max)) * 2.0 - 1.0
        }
        
        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / sampleRate // time in seconds
            var sample: Float = 0.0
            
            switch profile {
            case .cherryMXBlue:
                sample = synthesizeCherryBlue(t: t, category: category, noise: randomNoise)
            case .alpacaLinear:
                sample = synthesizeAlpacaLinear(t: t, category: category, noise: randomNoise)
            case .topreTactile:
                sample = synthesizeTopreTactile(t: t, category: category, noise: randomNoise)
            case .holyPanda:
                sample = synthesizeHolyPanda(t: t, category: category, noise: randomNoise)
            case .ibmModelM:
                sample = synthesizeIBMModelM(t: t, category: category, noise: randomNoise)
            case .novelKeysCream:
                sample = synthesizeNovelKeysCream(t: t, category: category, noise: randomNoise)
            case .typewriter:
                sample = synthesizeTypewriter(t: t, category: category, noise: randomNoise)
            }
            
            // Soft clipping safety
            let clamped = max(-0.95, min(0.95, sample))
            
            for ch in 0..<channels {
                floatBuffers?[ch][frame] = clamped
            }
        }
        
        return pcmBuffer
    }
    
    // MARK: - Cherry MX Blue (Sharp Click + Housing Snap)
    private static func synthesizeCherryBlue(t: Float, category: SoundCategory, noise: () -> Float) -> Float {
        switch category {
        case .keyDown, .backspaceDown, .enterDown:
            let clickDecay = exp(-t * 900.0)
            let clickFreq: Float = (category == .enterDown) ? 2600.0 : 3200.0
            let click = sin(2.0 * .pi * clickFreq * t) * clickDecay * 0.75
            
            let bodyDecay = exp(-t * 180.0)
            let bodyFreq: Float = (category == .backspaceDown) ? 380.0 : 450.0
            let body = sin(2.0 * .pi * bodyFreq * t) * bodyDecay * 0.35
            
            let noiseDecay = exp(-t * 1200.0)
            let impactNoise = noise() * noiseDecay * 0.2
            return click + body + impactNoise
            
        case .spaceDown:
            let clickDecay = exp(-t * 600.0)
            let click = sin(2.0 * .pi * 2200.0 * t) * clickDecay * 0.6
            let hollowDecay = exp(-t * 120.0)
            let hollow = sin(2.0 * .pi * 210.0 * t) * hollowDecay * 0.5
            let noiseDecay = exp(-t * 800.0)
            let noisePart = noise() * noiseDecay * 0.15
            return click + hollow + noisePart
            
        case .keyUp, .backspaceUp, .enterUp:
            let clickDecay = exp(-t * 1100.0)
            let click = sin(2.0 * .pi * 3600.0 * t) * clickDecay * 0.4
            let bodyDecay = exp(-t * 250.0)
            let body = sin(2.0 * .pi * 520.0 * t) * bodyDecay * 0.2
            return click + body
            
        case .spaceUp:
            let clickDecay = exp(-t * 800.0)
            let click = sin(2.0 * .pi * 2600.0 * t) * clickDecay * 0.45
            let bodyDecay = exp(-t * 160.0)
            let body = sin(2.0 * .pi * 280.0 * t) * bodyDecay * 0.3
            return click + body
        }
    }
    
    // MARK: - Alpaca Linear (Deep Thock / Low Frequency Impulse)
    private static func synthesizeAlpacaLinear(t: Float, category: SoundCategory, noise: () -> Float) -> Float {
        switch category {
        case .keyDown, .backspaceDown, .enterDown:
            let thockFreq: Float = (category == .backspaceDown) ? 160.0 : ((category == .enterDown) ? 140.0 : 190.0)
            let thockDecay = exp(-t * 140.0)
            let thock = sin(2.0 * .pi * thockFreq * t + sin(2.0 * .pi * 60.0 * t) * 0.2) * thockDecay * 0.7
            
            let contactDecay = exp(-t * 600.0)
            let contact = noise() * contactDecay * 0.15
            
            let subDecay = exp(-t * 90.0)
            let sub = sin(2.0 * .pi * 110.0 * t) * subDecay * 0.35
            return thock + contact + sub
            
        case .spaceDown:
            let spaceThockDecay = exp(-t * 80.0)
            let spaceThock = sin(2.0 * .pi * 115.0 * t) * spaceThockDecay * 0.8
            let subDecay = exp(-t * 60.0)
            let sub = sin(2.0 * .pi * 85.0 * t) * subDecay * 0.4
            let noiseDecay = exp(-t * 400.0)
            let softNoise = noise() * noiseDecay * 0.1
            return spaceThock + sub + softNoise
            
        case .keyUp, .backspaceUp, .enterUp:
            let topDecay = exp(-t * 220.0)
            let topSnap = sin(2.0 * .pi * 340.0 * t) * topDecay * 0.35
            let subDecay = exp(-t * 180.0)
            let sub = sin(2.0 * .pi * 210.0 * t) * subDecay * 0.2
            return topSnap + sub
            
        case .spaceUp:
            let topDecay = exp(-t * 140.0)
            let topSnap = sin(2.0 * .pi * 240.0 * t) * topDecay * 0.4
            let subDecay = exp(-t * 100.0)
            let sub = sin(2.0 * .pi * 150.0 * t) * subDecay * 0.25
            return topSnap + sub
        }
    }
    
    // MARK: - Topre (Tactile Rubber Dome Pop & Wooden Thump)
    private static func synthesizeTopreTactile(t: Float, category: SoundCategory, noise: () -> Float) -> Float {
        switch category {
        case .keyDown, .backspaceDown, .enterDown:
            let chirpFreq = 420.0 - (t * 4000.0)
            let popDecay = exp(-t * 160.0)
            let pop = sin(2.0 * .pi * max(180.0, chirpFreq) * t) * popDecay * 0.65
            
            let thumpDecay = exp(-t * 120.0)
            let thump = sin(2.0 * .pi * 260.0 * t) * thumpDecay * 0.35
            
            let frictionDecay = exp(-t * 450.0)
            let friction = noise() * frictionDecay * 0.12
            return pop + thump + friction
            
        case .spaceDown:
            let popDecay = exp(-t * 100.0)
            let pop = sin(2.0 * .pi * 220.0 * t) * popDecay * 0.75
            let thumpDecay = exp(-t * 70.0)
            let thump = sin(2.0 * .pi * 140.0 * t) * thumpDecay * 0.45
            let frictionDecay = exp(-t * 300.0)
            let friction = noise() * frictionDecay * 0.15
            return pop + thump + friction
            
        case .keyUp, .backspaceUp, .enterUp:
            let returnDecay = exp(-t * 200.0)
            let returnSnap = sin(2.0 * .pi * 480.0 * t) * returnDecay * 0.4
            let domeDecay = exp(-t * 150.0)
            let domePop = sin(2.0 * .pi * 310.0 * t) * domeDecay * 0.25
            return returnSnap + domePop
            
        case .spaceUp:
            let returnDecay = exp(-t * 130.0)
            let returnSnap = sin(2.0 * .pi * 320.0 * t) * returnDecay * 0.45
            let domeDecay = exp(-t * 100.0)
            let domePop = sin(2.0 * .pi * 210.0 * t) * domeDecay * 0.3
            return returnSnap + domePop
        }
    }
    
    // MARK: - Holy Panda (Heavy Tactile Snap & Long Stem Pole Impact)
    private static func synthesizeHolyPanda(t: Float, category: SoundCategory, noise: () -> Float) -> Float {
        switch category {
        case .keyDown, .backspaceDown, .enterDown:
            // Snappy tactile bump impulse (800 Hz transient snap)
            let snapDecay = exp(-t * 450.0)
            let snap = sin(2.0 * .pi * 850.0 * t) * snapDecay * 0.65
            
            // Long stem pole bottom-out clack (480 Hz resonant peak)
            let clackDecay = exp(-t * 180.0)
            let clack = sin(2.0 * .pi * 480.0 * t) * clackDecay * 0.5
            
            let noiseDecay = exp(-t * 800.0)
            let impact = noise() * noiseDecay * 0.18
            return snap + clack + impact
            
        case .spaceDown:
            let snapDecay = exp(-t * 300.0)
            let snap = sin(2.0 * .pi * 550.0 * t) * snapDecay * 0.6
            let clackDecay = exp(-t * 110.0)
            let clack = sin(2.0 * .pi * 320.0 * t) * clackDecay * 0.6
            let noiseDecay = exp(-t * 500.0)
            let impact = noise() * noiseDecay * 0.25
            return snap + clack + impact
            
        case .keyUp, .backspaceUp, .enterUp:
            let upSnapDecay = exp(-t * 400.0)
            let upSnap = sin(2.0 * .pi * 950.0 * t) * upSnapDecay * 0.4
            let housingDecay = exp(-t * 200.0)
            let housing = sin(2.0 * .pi * 420.0 * t) * housingDecay * 0.25
            return upSnap + housing
            
        case .spaceUp:
            let upSnapDecay = exp(-t * 250.0)
            let upSnap = sin(2.0 * .pi * 650.0 * t) * upSnapDecay * 0.45
            let housingDecay = exp(-t * 140.0)
            let housing = sin(2.0 * .pi * 260.0 * t) * housingDecay * 0.3
            return upSnap + housing
        }
    }
    
    // MARK: - IBM Model M (Buckling Spring Metal Ping + Steel Plate Impact)
    private static func synthesizeIBMModelM(t: Float, category: SoundCategory, noise: () -> Float) -> Float {
        switch category {
        case .keyDown, .backspaceDown, .enterDown:
            // 1. Sharp metal flipper leaf click (3400 Hz)
            let clickDecay = exp(-t * 700.0)
            let click = sin(2.0 * .pi * 3400.0 * t) * clickDecay * 0.7
            
            // 2. Buckling spring high-frequency ping / ring (1850 Hz & 2400 Hz metallic shimmer)
            let springDecay = exp(-t * 60.0) // long metallic tail
            let springPing = (sin(2.0 * .pi * 1850.0 * t) + sin(2.0 * .pi * 2420.0 * t) * 0.5) * springDecay * 0.25
            
            // 3. Heavy steel backplate impact (310 Hz thump)
            let plateDecay = exp(-t * 150.0)
            let plate = sin(2.0 * .pi * 310.0 * t) * plateDecay * 0.45
            
            return click + springPing + plate
            
        case .spaceDown:
            let clickDecay = exp(-t * 400.0)
            let click = sin(2.0 * .pi * 280.0 * t) * clickDecay * 0.6
            let springDecay = exp(-t * 50.0)
            let springPing = (sin(2.0 * .pi * 1450.0 * t) + sin(2.0 * .pi * 1980.0 * t) * 0.5) * springDecay * 0.35
            let plateDecay = exp(-t * 90.0)
            let plate = sin(2.0 * .pi * 180.0 * t) * plateDecay * 0.55
            return click + springPing + plate
            
        case .keyUp, .backspaceUp, .enterUp:
            let springDecay = exp(-t * 70.0)
            let springRing = sin(2.0 * .pi * 2100.0 * t) * springDecay * 0.2
            let releaseClickDecay = exp(-t * 800.0)
            let releaseClick = sin(2.0 * .pi * 3800.0 * t) * releaseClickDecay * 0.35
            return springRing + releaseClick
            
        case .spaceUp:
            let springDecay = exp(-t * 60.0)
            let springRing = sin(2.0 * .pi * 1600.0 * t) * springDecay * 0.25
            let releaseClickDecay = exp(-t * 600.0)
            let releaseClick = sin(2.0 * .pi * 2900.0 * t) * releaseClickDecay * 0.4
            return springRing + releaseClick
        }
    }
    
    // MARK: - NovelKeys Cream (Creamy Smooth Marbly Sound)
    private static func synthesizeNovelKeysCream(t: Float, category: SoundCategory, noise: () -> Float) -> Float {
        switch category {
        case .keyDown, .backspaceDown, .enterDown:
            // Creamy marble pop (240 Hz - 360 Hz damped sine pair)
            let popDecay = exp(-t * 220.0)
            let marble1 = sin(2.0 * .pi * 320.0 * t) * popDecay * 0.5
            let marble2 = sin(2.0 * .pi * 240.0 * t) * popDecay * 0.4
            
            // Soft self-lubricating POM housing glide noise
            let glideDecay = exp(-t * 750.0)
            let glide = noise() * glideDecay * 0.1
            
            return marble1 + marble2 + glide
            
        case .spaceDown:
            let popDecay = exp(-t * 110.0)
            let marble1 = sin(2.0 * .pi * 190.0 * t) * popDecay * 0.6
            let marble2 = sin(2.0 * .pi * 140.0 * t) * popDecay * 0.5
            let glideDecay = exp(-t * 400.0)
            let glide = noise() * glideDecay * 0.12
            return marble1 + marble2 + glide
            
        case .keyUp, .backspaceUp, .enterUp:
            let topDecay = exp(-t * 280.0)
            let topMarble = sin(2.0 * .pi * 410.0 * t) * topDecay * 0.3
            return topMarble
            
        case .spaceUp:
            let topDecay = exp(-t * 180.0)
            let topMarble = sin(2.0 * .pi * 260.0 * t) * topDecay * 0.35
            return topMarble
        }
    }
    
    // MARK: - Retro Typewriter (Cast Iron Strike + Paper Platen Slap)
    private static func synthesizeTypewriter(t: Float, category: SoundCategory, noise: () -> Float) -> Float {
        switch category {
        case .keyDown, .backspaceDown:
            // 1. Cast iron typebar strike impact (850 Hz sharp metalloid thud)
            let strikeDecay = exp(-t * 400.0)
            let strike = sin(2.0 * .pi * 850.0 * t) * strikeDecay * 0.7
            
            // 2. Paper & rubber platen slap (lowpass noise burst)
            let slapDecay = exp(-t * 300.0)
            let slap = noise() * slapDecay * 0.35
            
            // 3. Iron frame resonance ring (620 Hz tail)
            let frameDecay = exp(-t * 90.0)
            let frameRing = sin(2.0 * .pi * 620.0 * t) * frameDecay * 0.3
            
            return strike + slap + frameRing
            
        case .spaceDown, .enterDown:
            // Heavy carriage return lever / space bar thump + metal bell ping on enter
            let strikeDecay = exp(-t * 200.0)
            let strike = sin(2.0 * .pi * 380.0 * t) * strikeDecay * 0.8
            let slapDecay = exp(-t * 150.0)
            let slap = noise() * slapDecay * 0.4
            
            // Bell ring for Enter key!
            let bell = (category == .enterDown) ? sin(2.0 * .pi * 2400.0 * t) * exp(-t * 25.0) * 0.5 : 0.0
            
            return strike + slap + bell
            
        case .keyUp, .backspaceUp, .enterUp:
            let returnDecay = exp(-t * 350.0)
            let returnClick = sin(2.0 * .pi * 1200.0 * t) * returnDecay * 0.25
            let noiseDecay = exp(-t * 500.0)
            let springNoise = noise() * noiseDecay * 0.15
            return returnClick + springNoise
            
        case .spaceUp:
            let returnDecay = exp(-t * 250.0)
            let returnClick = sin(2.0 * .pi * 800.0 * t) * returnDecay * 0.3
            return returnClick
        }
    }
}
