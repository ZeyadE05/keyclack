# ⌨️ KeyClack

> **Satisfying mechanical keyboard audio for every macOS keystroke.**

**KeyClack** is a lightweight, native macOS menu bar application built with Swift and `AVAudioEngine`. It plays crisp, realistic mechanical keyboard switch sound effects system-wide in real-time as you type in any application.

---

## ✨ Features

- 🎧 **7 Built-in High-Fidelity Sound Profiles**:
  - ⚡ **Cherry MX Blue**: Sharp, satisfying click with tactile housing snap.
  - 🌊 **Alpaca Linear**: Deep, buttery low-frequency "thock".
  - ⬡ **Topre**: Tactile rubber dome pop with a warm wooden thump.
  - ✨ **Holy Panda**: Heavy tactile snap with long-stem pole clack.
  - 🔔 **IBM Model M**: Authentic buckling spring ping with steel plate impact.
  - 💧 **NovelKeys Cream**: Smooth, creamy, marbly acoustic profile.
  - ⌨️ **Retro Typewriter**: Heavy cast iron typebar strike with paper platen slap & carriage return bell on Enter.
- 🎛️ **Native Menu Bar Controller**:
  - Live Volume Slider (0% to 100%).
  - One-click Mute / Unmute (`Cmd+S` shortcut support).
  - Quick Sound Profile Switcher with instant audio preview.
  - Real-time Accessibility Permission Monitoring & Quick Fix trigger.
  - **Launch at Login** toggle.
- ⚡ **Zero External Dependencies**:
  - Uses macOS native `AVAudioEngine` with a multi-node round-robin player pool (`AVAudioPlayerNode`) for ultra-low latency playback.
  - High-definition in-memory procedural audio synthesis — no large sample download required!
- 📁 **Custom WAV Sound Pack Support**:
  - Override synthesized profiles or add your own `.wav` samples by placing files into `~/.config/keyclack/sounds/<Profile Name>/`.

---

## 📋 Requirements

- **macOS 13.0 (Ventura)** or later.
- **Accessibility Permissions** (required by macOS to intercept system-wide key press and key release events).
- **Swift 5.9+** / **Xcode Command Line Tools** (for building from source).

---

## 🚀 Quick Start & Building

### 1. Clone the Repository

```bash
git clone https://github.com/ZeyadE05/keyclack.git
cd keyclack
```

### 2. Build & Run directly with Swift Package Manager

```bash
swift run
```

### 3. Build standalone macOS App Bundle (`KeyClack.app`)

Use the included build script to compile a release binary and generate an ad-hoc signed `.app` bundle:

```bash
chmod +x build.sh
./build.sh
```

The compiled application bundle will be saved at:
```text
build/KeyClack.app
```

To launch the app bundle:
```bash
open build/KeyClack.app
```

---

## 🔐 Accessibility Permissions Setup

Because macOS protects keyboard inputs for security, system-wide key loggers and event taps require **Accessibility Permissions**.

1. When you first launch **KeyClack**, a dialog will ask for Accessibility access.
2. Open **System Settings** → **Privacy & Security** → **Accessibility**.
3. Toggle the switch next to **KeyClack** (or your Terminal / IDE if running via `swift run`) to **ON**.
4. If permissions are missing, KeyClack's menu bar icon will display `Accessibility: Required (Click to Fix)`. Clicking it will open System Settings directly for you.

---

## 📁 Custom Sound Packs

You can supply your own custom `.wav` sound files for any profile!

KeyClack checks the user config directory `~/.config/keyclack/sounds/<Profile Name>/` on startup and profile selection. If custom WAV files exist, KeyClack loads them instead of procedural audio.

### Supported File Structure:
```text
~/.config/keyclack/sounds/Cherry MX Blue (Clicky)/
├── keyDown.wav
├── keyUp.wav
├── spaceDown.wav
├── spaceUp.wav
├── backspaceDown.wav
├── backspaceUp.wav
├── enterDown.wav
└── enterUp.wav
```

---

## 🏗 Project Structure

```text
KeyClack/
├── Package.swift               # Swift PM executable package manifest
├── Info.plist                  # macOS App bundle property list
├── AppIcon.icns                # Application icon bundle
├── build.sh                    # Script to build & package KeyClack.app
├── make_icon.sh                # Script to generate AppIcon.icns
├── Sources/
│   └── KeyClack/
│       ├── main.swift          # AppKit NSApplication entry point & delegate
│       ├── Audio/
│       │   ├── SoundEngine.swift           # AVAudioEngine & player pool manager
│       │   └── ProceduralSynthesizer.swift # High-fidelity PCM sound synthesizer
│       ├── Input/
│       │   └── EventTapManager.swift       # CGEventTap system key listener
│       ├── Permissions/
│       │   └── AccessibilityManager.swift  # AXIsProcessTrusted monitoring
│       ├── AutoStart/
│       │   └── LaunchAtLoginManager.swift # SMAppService auto-launch helper
│       └── UI/
│           └── MenuBarController.swift     # NSStatusItem & NSMenu UI controller
└── README.md
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.

---

## 🛠 Built With

- **Swift / SwiftUI**
- **Core Audio & I/O Kit APIs**
- Prototyped and built with assistance from AI-assisted development tools (Cursor / Claude)

