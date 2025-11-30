# Gravity Volume Control 🪨🔊

[![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![Tests](https://img.shields.io/badge/tests-48%20passed-brightgreen.svg)](#テスト-testing)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](../../LICENSE)

**🌍 [English](../../README.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [Русский](README_ru.md) | [فارسی](README_fa.md) | [العربية](README_ar.md)**

**MacBookのトラックパッドを「世界で最も不便な音量コントローラー」に変える**

[Gravity Volume Control] は、MacBookのトラックパッドに搭載された感圧センサー (Force Touch) を利用し、**「乗せた物の重さ」でシステム音量を制御する** ジョークアプリケーションです。

エンジニア界隈で人気の「最悪な音量UIコンテスト (Bad Volume Control UI)」へのオマージュとして開発されました。

https://github.com/user-attachments/assets/demo-video-placeholder

---

## 目次

- [使い方](#使い方-the-bad-experience)
- [動作環境](#動作環境-requirements)
- [インストール](#インストール-installation)
- [開発](#開発-development)
- [アーキテクチャ](#アーキテクチャ-architecture)
- [プロジェクト構成](#プロジェクト構成-project-structure)
- [学習できる技術要素](#学習できる技術要素-for-engineers)
- [免責事項](#免責事項-disclaimer)

---

## 使い方 (The "Bad" Experience)

1. アプリを起動します。
2. トラックパッドに指を置きます（通電のため必須）。
3. その指の横に **「重り」** を置きます。
   - 🪶 **軽いもの (例: 消しゴム)** → 🔈 音量: 小
   - 🍺 **重いもの (例: 満タンのマグカップ)** → 🔊 音量: 大
4. 動画を見ている間、**その重い物をずっとトラックパッドに乗せ続けてください**。物をどかすと、即座にミュートになります。

---

## 動作環境 (Requirements)

| 項目 | 要件 |
|------|------|
| OS | macOS 13.0 (Ventura) 以上 |
| ハードウェア | Force Touch 対応トラックパッド搭載 MacBook |
| Xcode | 16.0 以上 |
| Swift | 6.0 |

> **Note:** 外部トラックパッドや Magic Trackpad では動作しません。MacBook 内蔵トラックパッドのみ対応しています。

---

## インストール (Installation)

### Homebrew (推奨)

```bash
brew install --cask gravity-volume-control
```

### 手動インストール

1. [Releases](https://github.com/clearclown/volumeControlWithTrackWeight/releases) から最新の `.dmg` をダウンロード
2. `Gravity Volume Control.app` を `/Applications` にドラッグ
3. 初回起動時、「開発元を確認できない」と表示される場合は、システム設定 > プライバシーとセキュリティ から許可

### ソースからビルド

```bash
git clone https://github.com/clearclown/volumeControlWithTrackWeight.git
cd volumeControlWithTrackWeight
xcodebuild build -scheme TrackWeight -destination 'platform=macOS'
```

---

## 開発 (Development)

### 開発方針

このプロジェクトは **TDD (テスト駆動開発)** を採用しています。

- 新機能追加時は、まずテストを書く
- 実機での動作確認より、テストの成功を優先
- ViewModelは依存性注入 (DI) によりテスト可能な設計

### ビルド

```bash
# アプリをビルド
xcodebuild build -scheme TrackWeight -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### テスト (Testing)

```bash
# 全テストを実行
xcodebuild test -scheme TrackWeight -destination 'platform=macOS' \
  -only-testing:TrackWeightTests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

**テストカバレッジ:**

| テストスイート | テスト数 | 対象 |
|--------------|---------|------|
| `ScaleViewModelTests` | 17 | 基本的な秤機能 |
| `WeighingViewModelTests` | 24 | 計量ワークフロー・状態遷移 |
| `WeighingStateTests` | 7 | 状態の等価性 |
| **合計** | **48** | - |

### AI開発支援

AI アシスタント (Claude Code 等) での開発時は `CLAUDE.md` を参照してください。TDDルールや禁止事項が記載されています。

---

## アーキテクチャ (Architecture)

このアプリは、ハードウェアからの入力をリアクティブにUIとシステム設定へ反映させる **MVVM (Model-View-ViewModel)** パターンを採用しています。

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

### データフロー

1. **Data Source:** `OpenMultitouchSupport` がハードウェア割り込みをフックし、タッチイベントを生成。
2. **ViewModel:** `ScaleViewModel` が非同期ストリーム (`for await`) でデータを受け取り、ノイズ除去と数値変換（圧力 0.0〜1.0 → 音量 0.0〜100.0）を行う。
3. **View:** SwiftUIが `@Published` プロパティの変更を検知し、画面上の「重そうなアニメーション」を描画。
4. **System:** 同時にバックグラウンドでシステム音量を更新。

### 依存性注入 (DI)

ViewModelはテスト可能な設計になっています：

```swift
// 本番環境（デフォルト）
let viewModel = ScaleViewModel() // OMSManager.shared を使用

// テスト環境
let mockProvider = MockTouchDataProvider()
let viewModel = ScaleViewModel(touchProvider: mockProvider)
```

---

## プロジェクト構成 (Project Structure)

```
volumeControlWithTrackWeight/
├── TrackWeight/                    # メインアプリケーション
│   ├── TrackWeightApp.swift        # エントリーポイント
│   ├── ContentView.swift           # メイン画面
│   ├── ScaleView.swift             # 秤UI
│   ├── ScaleViewModel.swift        # 秤ロジック
│   ├── WeighingView.swift          # 計量UI
│   ├── WeighingViewModel.swift     # 計量ワークフロー
│   ├── WeighingState.swift         # 状態定義
│   └── TouchDataProviding.swift    # DI用プロトコル
│
├── TrackWeightTests/               # ユニットテスト
│   ├── Mocks/
│   │   └── MockTouchDataProvider.swift
│   ├── ScaleViewModelTests.swift
│   ├── WeighingViewModelTests.swift
│   └── WeighingStateTests.swift
│
├── CLAUDE.md                       # AI開発ガイドライン
└── README.md
```

---

## 学習できる技術要素 (For Engineers)

一見するとただのジョークアプリですが、内部では高度な技術的挑戦が行われています。Swiftエンジニアとして以下の要素を実践的に学ぶことができます。

### 1. Apple Private APIs & ハードウェア制御

通常アクセスできないトラックパッドの生データ（圧力、接触面積）を取得するために、プライベートフレームワークである `OpenMultitouchSupport` の解析と利用方法を学べます。

- **Key Files:** `ContentViewModel.swift`, `TouchDataProviding.swift`

### 2. Swift Modern Concurrency (Async/Await)

センサーから絶え間なく流れてくるデータストリームを、Swift 6.0時代の最新の並行処理モデルで効率的に処理しています。

- `AsyncStream` を用いたイベント監視
- `Task` と `@MainActor` によるUIスレッドへの安全なデータバインディング
- **Key Files:** `ScaleViewModel.swift`, `WeighingViewModel.swift`

### 3. 信号処理 (Signal Processing)

センサーの生値は常に揺れ動いています（ノイズ）。これを不快感のない滑らかな音量変化に変換するためのアルゴリズム実装が含まれています。

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `historySize` | 10 | 移動平均のウィンドウサイズ |
| `rateOfChangeThreshold` | 5.0 | 物体検出の変化率閾値 |
| `stabilityThreshold` | 2.0 | 安定判定の許容範囲 |
| `fingerHoldDuration` | 3.0秒 | 指検出の待機時間 |
| `stabilityDuration` | 3.0秒 | 安定待機時間 |

- **Key Files:** `WeighingViewModel.swift`

### 4. macOS システム統合

アプリ内だけでなく、OS全体のマスターボリュームを制御するための `AudioToolbox` や `Core Audio` との連携、およびサンドボックス環境下での権限管理 (`entitlements`) について学べます。

### 5. テスト可能な設計 (Testable Architecture)

プライベートAPIに依存するコードでも、プロトコル抽象化と依存性注入によりユニットテストを可能にする設計パターンを学べます。

```swift
protocol TouchDataProviding: AnyObject, Sendable {
    var touchDataStream: AsyncStream<[OMSTouchData]> { get }
    @MainActor func startListening() -> Bool
    @MainActor func stopListening() -> Bool
}
```

---

## 貢献 (Contributing)

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. **テストを書いてから**実装
4. テストが全てパスすることを確認 (`xcodebuild test ...`)
5. 変更をコミット (`git commit -m 'Add amazing feature'`)
6. ブランチをプッシュ (`git push origin feature/amazing-feature`)
7. Pull Request を作成

---

## 免責事項 (Disclaimer)

> **警告:** トラックパッドに過度な重さをかけたり、鋭利な物を置いたりしないでください。トラックパッドが破損する恐れがあります。本アプリの使用によって生じたハードウェアの損傷について、開発者は一切の責任を負いません。

**これはジョークです。本気で日常利用しないでください。**

---

## ライセンス (License)

MIT License - 詳細は [LICENSE](../../LICENSE) を参照してください。
