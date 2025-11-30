# Gravity Volume Control 🪨🔊

[![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Tests](https://img.shields.io/badge/tests-48%20passed-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)

**🌍 [日本語](docs/readmeLang/README_ja.md) | [简体中文](docs/readmeLang/README_zh-CN.md) | [繁體中文](docs/readmeLang/README_zh-TW.md) | [Русский](docs/readmeLang/README_ru.md) | [فارسی](docs/readmeLang/README_fa.md) | [العربية](docs/readmeLang/README_ar.md)**

**Transform your MacBook's trackpad into "The World's Most Inconvenient Volume Controller"**

[Gravity Volume Control] is a joke application that uses the Force Touch pressure sensor built into MacBook trackpads to **control system volume by the weight of objects placed on it**.

Developed as an homage to the popular "Bad Volume Control UI Contest" in the engineering community.

https://github.com/user-attachments/assets/demo-video-placeholder

---

## Table of Contents

- [How to Use](#how-to-use-the-bad-experience)
- [Requirements](#requirements)
- [Installation](#installation)
- [Development](#development)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Learning Opportunities](#learning-opportunities-for-engineers)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)

---

## How to Use (The "Bad" Experience)

1. Launch the app.
2. Place your finger on the trackpad (required for electrical conductivity).
3. Place a **"weight"** next to your finger.
   - 🪶 **Light objects (e.g., eraser)** → 🔈 Volume: Low
   - 🍺 **Heavy objects (e.g., full mug)** → 🔊 Volume: High
4. **Keep that heavy object on the trackpad the entire time** you're watching a video. If you remove it, the audio instantly mutes.

---

## Requirements

| Item | Requirement |
|------|-------------|
| OS | macOS 13.0 (Ventura) or later |
| Hardware | MacBook with Force Touch trackpad |
| Xcode | 16.0 or later |
| Swift | 6.0 |

> **Note:** Does NOT work with external trackpads or Magic Trackpad. Only supports built-in MacBook trackpads.

---

## Installation

### Homebrew (Recommended)

```bash
brew install --cask gravity-volume-control
```

### Manual Installation

1. Download the latest `.dmg` from [Releases](https://github.com/clearclown/volumeControlWithTrackWeight/releases)
2. Drag `Gravity Volume Control.app` to `/Applications`
3. On first launch, if you see "Developer cannot be verified", go to System Settings > Privacy & Security and allow it

### Build from Source

```bash
git clone https://github.com/clearclown/volumeControlWithTrackWeight.git
cd volumeControlWithTrackWeight
xcodebuild build -scheme TrackWeight -destination 'platform=macOS'
```

---

## Development

### Development Philosophy

This project follows **TDD (Test-Driven Development)**.

- Write tests first when adding new features
- Prioritize test success over manual device testing
- ViewModels use Dependency Injection (DI) for testable design

### Build

```bash
# Build the app
xcodebuild build -scheme TrackWeight -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### Testing

```bash
# Run all tests
xcodebuild test -scheme TrackWeight -destination 'platform=macOS' \
  -only-testing:TrackWeightTests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

**Test Coverage:**

| Test Suite | Test Count | Target |
|------------|------------|--------|
| `ScaleViewModelTests` | 17 | Basic scale functionality |
| `WeighingViewModelTests` | 24 | Weighing workflow & state transitions |
| `WeighingStateTests` | 7 | State equality |
| **Total** | **48** | - |

### AI Development Support

When developing with AI assistants (Claude Code, etc.), refer to `CLAUDE.md` for TDD rules and guidelines.

---

## Architecture

This app uses the **MVVM (Model-View-ViewModel)** pattern to reactively reflect hardware input to both UI and system settings.

```mermaid
graph TD
    Hardware[Trackpad Force Sensors] -->|Raw Pressure Data| OMS[OpenMultitouchSupport Framework]
    OMS -->|Async Stream| VM[ScaleViewModel / WeighingViewModel]

    subgraph "Application Logic"
        VM -->|Signal Processing| Logic[Smoothing & Mapping]
        Logic -->|Calculated Volume| PublishedVar[@Published volume]
    end

    PublishedVar -->|Binding| View[SwiftUI View]
    PublishedVar -->|Side Effect| AudioAPI[macOS System Audio]
```

### Data Flow

1. **Data Source:** `OpenMultitouchSupport` hooks hardware interrupts and generates touch events.
2. **ViewModel:** `ScaleViewModel` receives data via async stream (`for await`), performs noise reduction and value conversion (pressure 0.0~1.0 → volume 0.0~100.0).
3. **View:** SwiftUI detects `@Published` property changes and renders "heavy-looking animations".
4. **System:** Simultaneously updates system volume in background.

### Dependency Injection (DI)

ViewModels are designed for testability:

```swift
// Production (default)
let viewModel = ScaleViewModel() // Uses OMSManager.shared

// Testing
let mockProvider = MockTouchDataProvider()
let viewModel = ScaleViewModel(touchProvider: mockProvider)
```

---

## Project Structure

```
volumeControlWithTrackWeight/
├── TrackWeight/                    # Main application
│   ├── TrackWeightApp.swift        # Entry point
│   ├── ContentView.swift           # Main screen
│   ├── ScaleView.swift             # Scale UI
│   ├── ScaleViewModel.swift        # Scale logic
│   ├── WeighingView.swift          # Weighing UI
│   ├── WeighingViewModel.swift     # Weighing workflow
│   ├── WeighingState.swift         # State definitions
│   └── TouchDataProviding.swift    # DI protocol
│
├── TrackWeightTests/               # Unit tests
│   ├── Mocks/
│   │   └── MockTouchDataProvider.swift
│   ├── ScaleViewModelTests.swift
│   ├── WeighingViewModelTests.swift
│   └── WeighingStateTests.swift
│
├── CLAUDE.md                       # AI development guidelines
└── README.md
```

---

## Learning Opportunities (For Engineers)

At first glance, this is just a joke app, but it contains advanced technical challenges. As a Swift engineer, you can practically learn the following:

### 1. Apple Private APIs & Hardware Control

Learn how to analyze and use the private framework `OpenMultitouchSupport` to access raw trackpad data (pressure, contact area) that's normally inaccessible.

- **Key Files:** `ContentViewModel.swift`, `TouchDataProviding.swift`

### 2. Swift Modern Concurrency (Async/Await)

Efficiently process continuous data streams from sensors using Swift 6.0's latest concurrency model.

- Event monitoring with `AsyncStream`
- Safe UI thread data binding with `Task` and `@MainActor`
- **Key Files:** `ScaleViewModel.swift`, `WeighingViewModel.swift`

### 3. Signal Processing

Raw sensor values constantly fluctuate (noise). Includes algorithm implementations to convert this into smooth, comfortable volume changes.

| Parameter | Value | Description |
|-----------|-------|-------------|
| `historySize` | 10 | Moving average window size |
| `rateOfChangeThreshold` | 5.0 | Object detection rate threshold |
| `stabilityThreshold` | 2.0 | Stability judgment tolerance |
| `fingerHoldDuration` | 3.0s | Finger detection wait time |
| `stabilityDuration` | 3.0s | Stability wait time |

- **Key Files:** `WeighingViewModel.swift`

### 4. macOS System Integration

Learn about integration with `AudioToolbox` and `Core Audio` to control the OS-wide master volume, and permission management in sandbox environments (`entitlements`).

### 5. Testable Architecture

Learn design patterns that enable unit testing even for code dependent on private APIs through protocol abstraction and dependency injection.

```swift
protocol TouchDataProviding: AnyObject, Sendable {
    var touchDataStream: AsyncStream<[OMSTouchData]> { get }
    @MainActor func startListening() -> Bool
    @MainActor func stopListening() -> Bool
}
```

---

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. **Write tests first** before implementing
4. Ensure all tests pass (`xcodebuild test ...`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push the branch (`git push origin feature/amazing-feature`)
7. Create a Pull Request

---

## Disclaimer

> **Warning:** Do not place excessive weight or sharp objects on the trackpad. This may damage your trackpad. The developer assumes no responsibility for any hardware damage caused by using this app.

**This is a joke. Please don't use it for daily activities.**

---

## License

MIT License - See [LICENSE](LICENSE) for details.
