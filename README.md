# Gravity Volume Control 🪨🔊

[![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Tests](https://img.shields.io/badge/tests-48%20passed-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![Mass Destruction](https://img.shields.io/badge/trackpad%20destruction-guaranteed-red.svg)](#disclaimer)
[![Sanity](https://img.shields.io/badge/developer%20sanity-questionable-yellow.svg)](#disclaimer)

**🌍 [日本語](docs/readmeLang/README_ja.md) | [简体中文](docs/readmeLang/README_zh-CN.md) | [繁體中文](docs/readmeLang/README_zh-TW.md) | [Русский](docs/readmeLang/README_ru.md) | [فارسی](docs/readmeLang/README_fa.md) | [العربية](docs/readmeLang/README_ar.md)**

---

## 🏆 Congratulations! You've Found The World's Most Inconvenient Volume Controller

> *"Why use a slider when you can use gravity?"* — No one, ever

**Gravity Volume Control** turns your precious MacBook's Force Touch trackpad into a **$2000+ kitchen scale that also happens to control volume**. Because apparently, pressing a button was too easy.

### 🍴 Forked with Love (and Questionable Judgment)

This masterpiece of terrible UX is a fork of [KrishKrosh/TrackWeight](https://github.com/KrishKrosh/TrackWeight) — the original genius who thought "Hey, what if we made volume control require a physics degree?"

We took that idea and made it ~~worse~~ *more feature-rich*.

---

## 🎬 Watch The Chaos Unfold

https://github.com/user-attachments/assets/7eaf9e0b-3dec-4829-b868-f54a8fd53a84

*Yes, that's a real person. Yes, they're actually controlling volume with objects. No, we don't know why either.*

---

## 📖 Table of Contents

- [The "Experience"](#-how-to-ruin-your-day-usage)
- [Requirements](#-requirements-for-self-destruction)
- [Installation](#-installation-of-regret)
- [Development](#-development-a-journey-of-pain)
- [Architecture](#-architecture-over-engineered-for-a-joke)
- [Learning Opportunities](#-learning-opportunities-the-only-redeeming-quality)
- [Contributing](#-contributing-misery-loves-company)
- [Disclaimer](#-disclaimer-please-read-seriously)

---

## 🤡 How to Ruin Your Day (Usage)

1. **Launch the app** and immediately question your life choices
2. **Place your finger on the trackpad** (required for conductivity, like you're some kind of human ground wire)
3. **Place a "weight" next to your finger**
   - 🪶 **Light stuff (eraser)** → 🔈 Quiet, like your regret
   - 🍺 **Heavy stuff (full mug)** → 🔊 LOUD, like your coworkers asking "WHY?"
4. **Keep that object there THE ENTIRE TIME** you're watching videos
   - Remove it? **Instant mute.**
   - Sneeze? **Mute.**
   - Cat walks by? **Chaos.**
   - Need to actually use your computer? **Too bad.**

### 💡 Pro Tips Nobody Asked For

- Coffee mugs work great until you spill coffee on your $3000 MacBook Pro
- Your phone is the perfect weight... until someone calls
- Textbooks provide stable volume... and remind you of your student loans
- Your dignity has zero weight and therefore cannot control volume

---

## 💀 Requirements (For Self-Destruction)

| Item | Requirement | Reality Check |
|------|-------------|---------------|
| OS | macOS 13.0+ | Because we use modern APIs to do unmodern things |
| Hardware | Force Touch trackpad | The $300 component you're about to abuse |
| Xcode | 16.0+ | To compile your regrets |
| Swift | 6.0 | Modern language, ancient wisdom: "don't do this" |
| Sanity | Optional | Clearly we didn't have any |

> **⚠️ IMPORTANT:** Does NOT work with external trackpads. Apple apparently designed Magic Trackpad for people who *don't* want to put mugs on it. Cowards.

---

## 📦 Installation (Of Regret)

### Homebrew (For Those Who Trust Strangers)

```bash
# You're really doing this, huh?
brew install --cask gravity-volume-control
```

### Manual Installation (For Control Freaks)

1. Download `.dmg` from [Releases](https://github.com/clearclown/volumeControlWithTrackWeight/releases) (we won't judge... much)
2. Drag to `/Applications` (the point of no return)
3. When macOS says "unidentified developer" — yeah, that tracks

### Build from Source (For Masochists)

```bash
git clone https://github.com/clearclown/volumeControlWithTrackWeight.git
cd volumeControlWithTrackWeight

# Compile 1700+ lines of code for a joke
xcodebuild build -scheme TrackWeight -destination 'platform=macOS'

# Congratulations, you now mass-produce bad decisions
```

---

## 🛠 Development (A Journey of Pain)

### Our Development Philosophy: TDD (Tragedy-Driven Development)

This project follows **Test-Driven Development** because if we're going to build something useless, we're going to build it *correctly*.

- ✅ Write tests before features (the only responsible thing we do)
- ✅ 48 tests, all passing (the app works, just... why?)
- ✅ Dependency Injection for testability (because we're professionals™)

### Test Coverage (Our Only Pride)

| Test Suite | Tests | What It Proves |
|------------|-------|----------------|
| `ScaleViewModelTests` | 17 | The scale works. Unfortunately. |
| `WeighingViewModelTests` | 24 | Weight detection is accurate. Great. |
| `WeighingStateTests` | 7 | State machine works. Yay? |
| **Total** | **48** | We put more effort into tests than the concept |

```bash
# Run tests (the only command that makes sense)
xcodebuild test -scheme TrackWeight -destination 'platform=macOS' \
  -only-testing:TrackWeightTests
```

---

## 🏗 Architecture (Over-Engineered for a Joke)

We used **MVVM** because if you're going to do something stupid, do it with proper software architecture.

```
┌─────────────────────────────────────────────────────────────────┐
│                    THE FLOW OF REGRET                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐     ┌─────────────────────┐                  │
│  │  Your Mug    │────▶│  Force Touch Sensor │                  │
│  │  (Innocent)  │     │  (Being Abused)     │                  │
│  └──────────────┘     └──────────┬──────────┘                  │
│                                  │                              │
│                                  ▼                              │
│                    ┌─────────────────────────┐                 │
│                    │ OpenMultitouchSupport   │                 │
│                    │ (Private API we stole)  │                 │
│                    └──────────┬──────────────┘                 │
│                               │                                 │
│                               ▼                                 │
│         ┌─────────────────────────────────────────┐            │
│         │            ViewModel Layer              │            │
│         │  ┌─────────────┐  ┌─────────────────┐  │            │
│         │  │ ScaleVM     │  │ WeighingVM      │  │            │
│         │  │ (Math)      │  │ (More Math)     │  │            │
│         │  └─────────────┘  └─────────────────┘  │            │
│         └───────────────────┬─────────────────────┘            │
│                             │                                   │
│              ┌──────────────┴──────────────┐                   │
│              ▼                              ▼                   │
│    ┌──────────────────┐          ┌─────────────────┐           │
│    │   SwiftUI View   │          │  System Audio   │           │
│    │ (Pretty Useless) │          │ (Actual Change) │           │
│    └──────────────────┘          └─────────────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### The Data Flow (A Tragedy in 4 Acts)

1. **Act 1:** Your mug innocently sits on the trackpad
2. **Act 2:** Private APIs we shouldn't be using capture pressure data
3. **Act 3:** Complex signal processing (moving averages, noise reduction) calculates weight
4. **Act 4:** System volume changes. Your coworkers judge you.

### Signal Processing Parameters (Yes, We're Serious)

| Parameter | Value | Why We Need This |
|-----------|-------|------------------|
| `historySize` | 10 | Moving average window (your coffee shakes) |
| `rateOfChangeThreshold` | 5.0 | Object detection (is that a phone or a stapler?) |
| `stabilityThreshold` | 2.0 | When to accept the weight (stop trembling!) |
| `stabilityDuration` | 3.0s | How long to wait (forever feels shorter) |

---

## 📚 Learning Opportunities (The Only Redeeming Quality)

Okay, real talk. Despite being absolutely unhinged, this project is actually a goldmine for learning:

### 1. 🔓 Apple Private APIs (Legal Gray Zone Speedrun)

Access the forbidden `OpenMultitouchSupport` framework. See what Apple doesn't want you to see. Feel like a hacker. Get rejected from the App Store.

### 2. ⚡ Swift 6.0 Concurrency (Async/Await in the Wild)

Real-world `AsyncStream` usage, `@MainActor` patterns, and `Task` management. Your future employer will never know this knowledge came from a mug-weighing app.

### 3. 📊 Signal Processing (DSP for Dummies)

Moving averages, rate-of-change detection, stability algorithms. It's like you're processing audio... but it's actually coffee mug data.

### 4. 🎭 MVVM + Dependency Injection (By the Book)

Protocol-based abstractions, mock objects, testable architecture. We wrote this joke app better than most production apps.

### 5. 🍎 macOS System Integration

Core Audio, AudioToolbox, entitlements. Control system volume programmatically. Use this power for good (not this).

---

## 🤝 Contributing (Misery Loves Company)

1. **Fork** this monument to poor decisions
2. **Create a branch** (`git checkout -b feature/even-worse-idea`)
3. **Write tests first** (we have standards, just not common sense)
4. **Make it worse** in a good way
5. **Submit a PR** and join our support group

### Ideas We Haven't Implemented Yet

- [ ] Control brightness with head tilting
- [ ] Change wallpaper based on ambient sound
- [ ] Adjust keyboard backlight with room temperature
- [ ] Send emails by blinking in morse code

---

## ⚠️ Disclaimer (Please Read, Seriously)

> **🚨 WARNING: This is not a joke section (ironically)**
>
> - Do NOT place heavy objects on your trackpad
> - Do NOT place liquids near your laptop
> - Do NOT blame us when you need a $500 trackpad replacement
> - Do NOT use this in production (why would you?)
> - Do NOT show this to your IT department
> - Do NOT tell Apple about this
>
> **The developers assume ZERO responsibility for:**
> - Broken trackpads
> - Spilled coffee
> - Confused family members
> - Lost productivity
> - Existential crises
> - Strained relationships with coworkers
> - Apple Genius Bar appointments

---

## 🙏 Acknowledgments

- [KrishKrosh/TrackWeight](https://github.com/KrishKrosh/TrackWeight) — The original mad scientist
- The "Worst Volume UI" meme community — For the inspiration
- Apple Engineers — Who definitely didn't intend this
- Our therapists — For listening

---

## 📜 License

MIT License — Because even chaos deserves freedom.

Use this code for whatever you want. We're not responsible. We were never responsible.

---

<div align="center">

**Made with 🤦 by developers who should know better**

*"The only winning move is not to play" — but we played anyway*

⭐ Star this repo to enable our bad behavior ⭐

</div>
