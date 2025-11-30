# Gravity Volume Control 🪨🔊

[![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Tests](https://img.shields.io/badge/tests-48%20passed-brightgreen.svg)](#测试)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](../../LICENSE)

**🌍 [English](../../README.md) | [日本語](README_ja.md) | [繁體中文](README_zh-TW.md) | [Русский](README_ru.md) | [فارسی](README_fa.md) | [العربية](README_ar.md)**

**将你的 MacBook 触控板变成"世界上最不方便的音量控制器"**

[Gravity Volume Control] 是一款搞笑应用程序，它利用 MacBook 触控板内置的 Force Touch 压力传感器，**通过放在上面的物体重量来控制系统音量**。

这是对工程师社区中流行的"最糟糕音量控制 UI 大赛"的致敬之作。

https://github.com/user-attachments/assets/demo-video-placeholder

---

## 目录

- [使用方法](#使用方法-the-bad-experience)
- [系统要求](#系统要求)
- [安装](#安装)
- [开发](#开发)
- [架构](#架构)
- [项目结构](#项目结构)
- [学习机会](#学习机会-for-engineers)
- [免责声明](#免责声明)

---

## 使用方法 (The "Bad" Experience)

1. 启动应用程序。
2. 将手指放在触控板上（需要导电）。
3. 在手指旁边放置一个 **"重物"**。
   - 🪶 **轻的物体（例如：橡皮擦）** → 🔈 音量：低
   - 🍺 **重的物体（例如：装满的马克杯）** → 🔊 音量：高
4. 在观看视频时，**必须一直将重物放在触控板上**。如果移开，声音会立即静音。

---

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | macOS 13.0 (Ventura) 或更高版本 |
| 硬件 | 配备 Force Touch 触控板的 MacBook |
| Xcode | 16.0 或更高版本 |
| Swift | 6.0 |

> **注意：** 不支持外接触控板或 Magic Trackpad。仅支持 MacBook 内置触控板。

---

## 安装

### Homebrew（推荐）

```bash
brew install --cask gravity-volume-control
```

### 手动安装

1. 从 [Releases](https://github.com/clearclown/volumeControlWithTrackWeight/releases) 下载最新的 `.dmg`
2. 将 `Gravity Volume Control.app` 拖到 `/Applications`
3. 首次启动时，如果看到"无法验证开发者"，请前往系统设置 > 隐私与安全性 中允许

### 从源码构建

```bash
git clone https://github.com/clearclown/volumeControlWithTrackWeight.git
cd volumeControlWithTrackWeight
xcodebuild build -scheme TrackWeight -destination 'platform=macOS'
```

---

## 开发

### 开发理念

本项目遵循 **TDD（测试驱动开发）**。

- 添加新功能时先编写测试
- 测试成功优先于设备上的手动测试
- ViewModel 使用依赖注入（DI）实现可测试设计

### 构建

```bash
# 构建应用
xcodebuild build -scheme TrackWeight -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### 测试

```bash
# 运行所有测试
xcodebuild test -scheme TrackWeight -destination 'platform=macOS' \
  -only-testing:TrackWeightTests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

**测试覆盖率：**

| 测试套件 | 测试数量 | 目标 |
|----------|----------|------|
| `ScaleViewModelTests` | 17 | 基本秤功能 |
| `WeighingViewModelTests` | 24 | 称重工作流和状态转换 |
| `WeighingStateTests` | 7 | 状态相等性 |
| **合计** | **48** | - |

### AI 开发支持

使用 AI 助手（Claude Code 等）开发时，请参阅 `CLAUDE.md` 了解 TDD 规则和指南。

---

## 架构

本应用使用 **MVVM（Model-View-ViewModel）** 模式，将硬件输入响应式地反映到 UI 和系统设置中。

```mermaid
graph TD
    Hardware[触控板压力传感器] -->|原始压力数据| OMS[OpenMultitouchSupport 框架]
    OMS -->|异步流| VM[ScaleViewModel / WeighingViewModel]

    subgraph "应用逻辑"
        VM -->|信号处理| Logic[平滑和映射]
        Logic -->|计算后的音量| PublishedVar[@Published volume]
    end

    PublishedVar -->|绑定| View[SwiftUI 视图]
    PublishedVar -->|副作用| AudioAPI[macOS 系统音频]
```

### 数据流

1. **数据源：** `OpenMultitouchSupport` 钩住硬件中断并生成触摸事件。
2. **ViewModel：** `ScaleViewModel` 通过异步流（`for await`）接收数据，执行降噪和值转换（压力 0.0~1.0 → 音量 0.0~100.0）。
3. **视图：** SwiftUI 检测 `@Published` 属性变化并渲染"看起来很重的动画"。
4. **系统：** 同时在后台更新系统音量。

### 依赖注入 (DI)

ViewModel 设计为可测试的：

```swift
// 生产环境（默认）
let viewModel = ScaleViewModel() // 使用 OMSManager.shared

// 测试环境
let mockProvider = MockTouchDataProvider()
let viewModel = ScaleViewModel(touchProvider: mockProvider)
```

---

## 项目结构

```
volumeControlWithTrackWeight/
├── TrackWeight/                    # 主应用程序
│   ├── TrackWeightApp.swift        # 入口点
│   ├── ContentView.swift           # 主屏幕
│   ├── ScaleView.swift             # 秤 UI
│   ├── ScaleViewModel.swift        # 秤逻辑
│   ├── WeighingView.swift          # 称重 UI
│   ├── WeighingViewModel.swift     # 称重工作流
│   ├── WeighingState.swift         # 状态定义
│   └── TouchDataProviding.swift    # DI 协议
│
├── TrackWeightTests/               # 单元测试
│   ├── Mocks/
│   │   └── MockTouchDataProvider.swift
│   ├── ScaleViewModelTests.swift
│   ├── WeighingViewModelTests.swift
│   └── WeighingStateTests.swift
│
├── CLAUDE.md                       # AI 开发指南
└── README.md
```

---

## 学习机会 (For Engineers)

乍一看这只是一个搞笑应用，但它包含了高级的技术挑战。作为 Swift 工程师，你可以实践学习以下内容：

### 1. Apple 私有 API 和硬件控制

学习如何分析和使用私有框架 `OpenMultitouchSupport` 来访问通常无法访问的原始触控板数据（压力、接触面积）。

- **关键文件：** `ContentViewModel.swift`, `TouchDataProviding.swift`

### 2. Swift 现代并发 (Async/Await)

使用 Swift 6.0 最新的并发模型高效处理来自传感器的连续数据流。

- 使用 `AsyncStream` 进行事件监控
- 使用 `Task` 和 `@MainActor` 实现安全的 UI 线程数据绑定
- **关键文件：** `ScaleViewModel.swift`, `WeighingViewModel.swift`

### 3. 信号处理

原始传感器值会不断波动（噪声）。包含将其转换为平滑、舒适音量变化的算法实现。

| 参数 | 值 | 描述 |
|------|-----|------|
| `historySize` | 10 | 移动平均窗口大小 |
| `rateOfChangeThreshold` | 5.0 | 物体检测速率阈值 |
| `stabilityThreshold` | 2.0 | 稳定性判断容差 |
| `fingerHoldDuration` | 3.0秒 | 手指检测等待时间 |
| `stabilityDuration` | 3.0秒 | 稳定等待时间 |

- **关键文件：** `WeighingViewModel.swift`

### 4. macOS 系统集成

学习与 `AudioToolbox` 和 `Core Audio` 的集成以控制全系统主音量，以及沙盒环境中的权限管理（`entitlements`）。

### 5. 可测试架构

学习通过协议抽象和依赖注入实现即使依赖私有 API 的代码也能进行单元测试的设计模式。

```swift
protocol TouchDataProviding: AnyObject, Sendable {
    var touchDataStream: AsyncStream<[OMSTouchData]> { get }
    @MainActor func startListening() -> Bool
    @MainActor func stopListening() -> Bool
}
```

---

## 贡献

1. Fork 此仓库
2. 创建功能分支（`git checkout -b feature/amazing-feature`）
3. **先编写测试**再实现
4. 确保所有测试通过（`xcodebuild test ...`）
5. 提交更改（`git commit -m 'Add amazing feature'`）
6. 推送分支（`git push origin feature/amazing-feature`）
7. 创建 Pull Request

---

## 免责声明

> **警告：** 请勿在触控板上放置过重或尖锐的物体。这可能会损坏你的触控板。开发者对因使用本应用造成的任何硬件损坏不承担责任。

**这是一个玩笑。请不要在日常生活中使用。**

---

## 许可证

MIT License - 详见 [LICENSE](../../LICENSE)。
