# CLAUDE.md - AI開発アシスタント向けガイドライン

## プロジェクト概要

**Gravity Volume Control** は、MacBookのトラックパッド感圧センサー（Force Touch）を使用し、乗せた物の重さでシステム音量を制御するmacOSアプリケーション。

- **言語**: Swift 6.0+
- **フレームワーク**: SwiftUI, Combine, OpenMultitouchSupport（プライベートAPI）
- **アーキテクチャ**: MVVM
- **最小対応**: macOS 13+

## 絶対厳守ルール

### 1. TDD（テスト駆動開発）必須

```
Red → Green → Refactor のサイクルを厳守
```

- **新機能追加時**: 必ず先にテストを書く
- **バグ修正時**: まず失敗するテストを書いてからコードを修正
- **リファクタリング時**: 既存テストが全てパスすることを確認してから実施

### 2. 実機テスト・実行の禁止

```
テストが通れば実装完了とみなす
```

- アプリのビルド・実行コマンド (`xcodebuild build`, `open *.app`) を実行しない
- 実機でのトラックパッドテストは人間が行う
- シミュレータでの動作確認も不要

### 3. テスト実行コマンド

```bash
# ユニットテストの実行
xcodebuild test \
  -project TrackWeight.xcodeproj \
  -scheme TrackWeight \
  -destination 'platform=macOS'
```

## ディレクトリ構造

```
volumeControlWithTrackWeight/
├── TrackWeight/                    # メインアプリケーション
│   ├── TrackWeightApp.swift        # エントリーポイント
│   ├── ContentView.swift           # メインView
│   ├── ContentViewModel.swift      # タッチデータ管理VM
│   ├── ScaleView.swift             # スケール表示View
│   ├── ScaleViewModel.swift        # 重量測定VM（AsyncStream使用）
│   ├── WeighingState.swift         # 状態定義（enum）
│   ├── WeighingViewModel.swift     # 計量ロジックVM（信号処理含む）
│   ├── HomeView.swift              # ホーム画面
│   ├── TrackWeightView.swift       # トラックパッドビュー
│   ├── SettingsView.swift          # 設定画面
│   ├── DebugView.swift             # デバッグ用View
│   └── Assets.xcassets/            # アセット
├── TrackWeightTests/               # ユニットテスト（要作成）
├── TrackWeight.xcodeproj/          # Xcodeプロジェクト
├── scripts/                        # ビルドスクリプト
└── .github/workflows/              # CI/CD
```

## アーキテクチャ

### データフロー

```
[Trackpad Hardware]
        ↓
[OpenMultitouchSupport] ← プライベートフレームワーク
        ↓ AsyncStream<[OMSTouchData]>
[ViewModel] ← @MainActor, ObservableObject
        ↓ @Published properties
[SwiftUI View] ← Binding
        ↓ Side Effect
[System Audio API]
```

### 主要コンポーネント

| ファイル | 責務 |
|---------|------|
| `ScaleViewModel` | 生の圧力データを受信し、ゼロ点補正を適用 |
| `WeighingViewModel` | 計量状態管理、信号処理（移動平均、変化率検出）、安定性判定 |
| `ContentViewModel` | デバイス選択、タッチデータのブリッジ |
| `WeighingState` | 状態マシン定義（welcome→waitingForFinger→waitingForItem→weighing→result） |

### 信号処理アルゴリズム

```swift
// 移動平均（ノイズ除去）
let historySize = 10
let avgPressure = pressureHistory.reduce(0, +) / Float(pressureHistory.count)

// 変化率検出（アイテム検知）
let rateOfChangeThreshold: Float = 5
let rateOfChange = pressureHistory.last! - pressureHistory.first!

// 安定性判定
let stabilityThreshold: Float = 2.0  // 許容変動幅
let stabilityDuration: TimeInterval = 3.0  // 安定必要時間
```

## テスト戦略

### モック設計

OpenMultitouchSupportはプライベートフレームワークのため、プロトコル抽象化が必要：

```swift
// プロトコル定義
protocol TouchDataProviding {
    var touchDataStream: AsyncStream<[OMSTouchData]> { get }
    func startListening() -> Bool
    func stopListening() -> Bool
}

// 本番実装
extension OMSManager: TouchDataProviding {}

// テスト用モック
class MockTouchDataProvider: TouchDataProviding {
    var mockTouchData: [OMSTouchData] = []
    // AsyncStreamを制御可能にする
}
```

### テストすべき項目

1. **WeighingViewModel**
   - 状態遷移（welcome → waitingForFinger → ... → result）
   - 移動平均の計算精度
   - 変化率による物体検知
   - 安定性判定ロジック

2. **ScaleViewModel**
   - ゼロ点補正
   - タッチ有無の検出

3. **WeighingState**
   - Equatable準拠の確認

### テストファイル命名規則

```
TrackWeightTests/
├── WeighingViewModelTests.swift
├── ScaleViewModelTests.swift
├── WeighingStateTests.swift
└── Mocks/
    └── MockTouchDataProvider.swift
```

## コーディング規約

### Swift

- `@MainActor` を ViewModel に適用
- `@Published` でリアクティブなプロパティ
- `Task` + `for await` で非同期ストリーム処理
- `weak self` でメモリリーク防止

### 命名規則

| 種類 | 規則 | 例 |
|------|------|-----|
| ViewModel | `*ViewModel` | `ScaleViewModel` |
| View | `*View` | `ScaleView` |
| State enum | `*State` | `WeighingState` |
| テスト | `*Tests` | `WeighingViewModelTests` |

### コメント

- 日本語コメント可
- 複雑なアルゴリズムには必ず説明を記載
- `// MARK: -` でセクション区切り

## AI開発時の注意事項

1. **ハードウェア依存コードの変更時**
   - OpenMultitouchSupportに依存する部分は慎重に
   - 必ずモック経由でテスト可能な設計を維持

2. **信号処理パラメータ変更時**
   - `historySize`, `rateOfChangeThreshold`, `stabilityThreshold` 等
   - 単体テストで境界値を確認

3. **状態遷移の変更時**
   - `WeighingState` の変更は影響範囲が大きい
   - 全状態パターンをテストでカバー

4. **新規ファイル作成時**
   - 対応するテストファイルも同時に作成
   - テストが先、実装が後

## よく使うコマンド

```bash
# テスト実行
xcodebuild test -project TrackWeight.xcodeproj -scheme TrackWeight -destination 'platform=macOS'

# ビルドのみ（実行しない）
xcodebuild build -project TrackWeight.xcodeproj -scheme TrackWeight -destination 'platform=macOS'

# クリーンビルド
xcodebuild clean build -project TrackWeight.xcodeproj -scheme TrackWeight
```

## 禁止事項チェックリスト

- [ ] `open` コマンドでアプリを起動していないか
- [ ] `xcodebuild` に `run` オプションを付けていないか
- [ ] テストを書く前に実装コードを書いていないか
- [ ] モックなしでハードウェア依存コードをテストしようとしていないか
