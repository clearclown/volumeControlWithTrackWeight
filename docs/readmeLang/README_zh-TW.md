# Gravity Volume Control 🪨🔊

[![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Tests](https://img.shields.io/badge/tests-48%20passed-brightgreen.svg)](#測試)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](../../LICENSE)

**🌍 [English](../../README.md) | [日本語](README_ja.md) | [简体中文](README_zh-CN.md) | [Русский](README_ru.md) | [فارسی](README_fa.md) | [العربية](README_ar.md)**

**將你的 MacBook 觸控板變成「世界上最不方便的音量控制器」**

[Gravity Volume Control] 是一款搞笑應用程式，它利用 MacBook 觸控板內建的 Force Touch 壓力感測器，**透過放在上面的物體重量來控制系統音量**。

這是對工程師社群中流行的「最糟糕音量控制 UI 大賽」的致敬之作。

https://github.com/user-attachments/assets/demo-video-placeholder

---

## 目錄

- [使用方法](#使用方法-the-bad-experience)
- [系統需求](#系統需求)
- [安裝](#安裝)
- [開發](#開發)
- [架構](#架構)
- [專案結構](#專案結構)
- [學習機會](#學習機會-for-engineers)
- [免責聲明](#免責聲明)

---

## 使用方法 (The "Bad" Experience)

1. 啟動應用程式。
2. 將手指放在觸控板上（需要導電）。
3. 在手指旁邊放置一個 **「重物」**。
   - 🪶 **輕的物體（例如：橡皮擦）** → 🔈 音量：低
   - 🍺 **重的物體（例如：裝滿的馬克杯）** → 🔊 音量：高
4. 在觀看影片時，**必須一直將重物放在觸控板上**。如果移開，聲音會立即靜音。

---

## 系統需求

| 項目 | 需求 |
|------|------|
| 作業系統 | macOS 13.0 (Ventura) 或更高版本 |
| 硬體 | 配備 Force Touch 觸控板的 MacBook |
| Xcode | 16.0 或更高版本 |
| Swift | 6.0 |

> **注意：** 不支援外接觸控板或 Magic Trackpad。僅支援 MacBook 內建觸控板。

---

## 安裝

### Homebrew（推薦）

```bash
brew install --cask gravity-volume-control
```

### 手動安裝

1. 從 [Releases](https://github.com/clearclown/volumeControlWithTrackWeight/releases) 下載最新的 `.dmg`
2. 將 `Gravity Volume Control.app` 拖到 `/Applications`
3. 首次啟動時，如果看到「無法驗證開發者」，請前往系統設定 > 隱私權與安全性 中允許

### 從原始碼建置

```bash
git clone https://github.com/clearclown/volumeControlWithTrackWeight.git
cd volumeControlWithTrackWeight
xcodebuild build -scheme TrackWeight -destination 'platform=macOS'
```

---

## 開發

### 開發理念

本專案遵循 **TDD（測試驅動開發）**。

- 新增功能時先撰寫測試
- 測試成功優先於裝置上的手動測試
- ViewModel 使用依賴注入（DI）實現可測試設計

### 建置

```bash
# 建置應用程式
xcodebuild build -scheme TrackWeight -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### 測試

```bash
# 執行所有測試
xcodebuild test -scheme TrackWeight -destination 'platform=macOS' \
  -only-testing:TrackWeightTests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

**測試覆蓋率：**

| 測試套件 | 測試數量 | 目標 |
|----------|----------|------|
| `ScaleViewModelTests` | 17 | 基本秤功能 |
| `WeighingViewModelTests` | 24 | 秤重工作流程和狀態轉換 |
| `WeighingStateTests` | 7 | 狀態相等性 |
| **合計** | **48** | - |

### AI 開發支援

使用 AI 助手（Claude Code 等）開發時，請參閱 `CLAUDE.md` 了解 TDD 規則和指南。

---

## 架構

本應用程式使用 **MVVM（Model-View-ViewModel）** 模式，將硬體輸入響應式地反映到 UI 和系統設定中。

```mermaid
graph TD
    Hardware[觸控板壓力感測器] -->|原始壓力資料| OMS[OpenMultitouchSupport 框架]
    OMS -->|非同步串流| VM[ScaleViewModel / WeighingViewModel]

    subgraph "應用程式邏輯"
        VM -->|訊號處理| Logic[平滑和對應]
        Logic -->|計算後的音量| PublishedVar[@Published volume]
    end

    PublishedVar -->|綁定| View[SwiftUI 視圖]
    PublishedVar -->|副作用| AudioAPI[macOS 系統音訊]
```

### 資料流

1. **資料來源：** `OpenMultitouchSupport` 鉤住硬體中斷並產生觸控事件。
2. **ViewModel：** `ScaleViewModel` 透過非同步串流（`for await`）接收資料，執行降噪和值轉換（壓力 0.0~1.0 → 音量 0.0~100.0）。
3. **視圖：** SwiftUI 偵測 `@Published` 屬性變化並渲染「看起來很重的動畫」。
4. **系統：** 同時在背景更新系統音量。

### 依賴注入 (DI)

ViewModel 設計為可測試的：

```swift
// 正式環境（預設）
let viewModel = ScaleViewModel() // 使用 OMSManager.shared

// 測試環境
let mockProvider = MockTouchDataProvider()
let viewModel = ScaleViewModel(touchProvider: mockProvider)
```

---

## 專案結構

```
volumeControlWithTrackWeight/
├── TrackWeight/                    # 主應用程式
│   ├── TrackWeightApp.swift        # 進入點
│   ├── ContentView.swift           # 主畫面
│   ├── ScaleView.swift             # 秤 UI
│   ├── ScaleViewModel.swift        # 秤邏輯
│   ├── WeighingView.swift          # 秤重 UI
│   ├── WeighingViewModel.swift     # 秤重工作流程
│   ├── WeighingState.swift         # 狀態定義
│   └── TouchDataProviding.swift    # DI 協定
│
├── TrackWeightTests/               # 單元測試
│   ├── Mocks/
│   │   └── MockTouchDataProvider.swift
│   ├── ScaleViewModelTests.swift
│   ├── WeighingViewModelTests.swift
│   └── WeighingStateTests.swift
│
├── CLAUDE.md                       # AI 開發指南
└── README.md
```

---

## 學習機會 (For Engineers)

乍看之下這只是一個搞笑應用程式，但它包含了進階的技術挑戰。作為 Swift 工程師，你可以實踐學習以下內容：

### 1. Apple 私有 API 和硬體控制

學習如何分析和使用私有框架 `OpenMultitouchSupport` 來存取通常無法存取的原始觸控板資料（壓力、接觸面積）。

- **關鍵檔案：** `ContentViewModel.swift`, `TouchDataProviding.swift`

### 2. Swift 現代並行處理 (Async/Await)

使用 Swift 6.0 最新的並行處理模型高效處理來自感測器的連續資料串流。

- 使用 `AsyncStream` 進行事件監控
- 使用 `Task` 和 `@MainActor` 實現安全的 UI 執行緒資料綁定
- **關鍵檔案：** `ScaleViewModel.swift`, `WeighingViewModel.swift`

### 3. 訊號處理

原始感測器值會不斷波動（雜訊）。包含將其轉換為平滑、舒適音量變化的演算法實作。

| 參數 | 值 | 描述 |
|------|-----|------|
| `historySize` | 10 | 移動平均視窗大小 |
| `rateOfChangeThreshold` | 5.0 | 物體偵測速率閾值 |
| `stabilityThreshold` | 2.0 | 穩定性判斷容差 |
| `fingerHoldDuration` | 3.0秒 | 手指偵測等待時間 |
| `stabilityDuration` | 3.0秒 | 穩定等待時間 |

- **關鍵檔案：** `WeighingViewModel.swift`

### 4. macOS 系統整合

學習與 `AudioToolbox` 和 `Core Audio` 的整合以控制全系統主音量，以及沙盒環境中的權限管理（`entitlements`）。

### 5. 可測試架構

學習透過協定抽象和依賴注入實現即使依賴私有 API 的程式碼也能進行單元測試的設計模式。

```swift
protocol TouchDataProviding: AnyObject, Sendable {
    var touchDataStream: AsyncStream<[OMSTouchData]> { get }
    @MainActor func startListening() -> Bool
    @MainActor func stopListening() -> Bool
}
```

---

## 貢獻

1. Fork 此儲存庫
2. 建立功能分支（`git checkout -b feature/amazing-feature`）
3. **先撰寫測試**再實作
4. 確保所有測試通過（`xcodebuild test ...`）
5. 提交變更（`git commit -m 'Add amazing feature'`）
6. 推送分支（`git push origin feature/amazing-feature`）
7. 建立 Pull Request

---

## 免責聲明

> **警告：** 請勿在觸控板上放置過重或尖銳的物體。這可能會損壞你的觸控板。開發者對因使用本應用程式造成的任何硬體損壞不承擔責任。

**這是一個玩笑。請不要在日常生活中使用。**

---

## 授權

MIT License - 詳見 [LICENSE](../../LICENSE)。
