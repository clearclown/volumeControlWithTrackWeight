# Gravity Volume Control 🪨🔊

**MacBookのトラックパッドを「世界で最も不便な音量コントローラー」に変える**

[Gravity Volume Control] は、MacBookのトラックパッドに搭載された感圧センサー (Force Touch) を利用し、**「乗せた物の重さ」でシステム音量を制御する** ジョークアプリケーションです。

エンジニア界隈で人気の「最悪な音量UIコンテスト (Bad Volume Control UI)」へのオマージュとして開発されました。

https://github.com/user-attachments/assets/demo-video-placeholder

## 使い方 (The "Bad" Experience)

1. アプリを起動します。
2. トラックパッドに指を置きます（通電のため必須）。
3. その指の横に **「重り」** を置きます。
   - 🪶 **軽いもの (例: 消しゴム)** → 🔈 音量: 小
   - 🍺 **重いもの (例: 満タンのマグカップ)** → 🔊 音量: 大
4. 動画を見ている間、**その重い物をずっとトラックパッドに乗せ続けてください**。物をどかすと、即座にミュートになります。

## 学習できる技術要素 (For Engineers)

一見するとただのジョークアプリですが、内部では高度な技術的挑戦が行われています。Swiftエンジニアとして以下の要素を実践的に学ぶことができます。

### 1. Apple Private APIs & ハードウェア制御
通常アクセスできないトラックパッドの生データ（圧力、接触面積）を取得するために、プライベートフレームワークである `OpenMultitouchSupport` の解析と利用方法を学べます。
- **Key Files:** `ContentViewModel.swift`, `Frameworks/OpenMultitouchSupport`

### 2. Swift Modern Concurrency (Async/Await)
センサーから絶え間なく流れてくるデータストリームを、Swift 6.0時代の最新の並行処理モデルで効率的に処理しています。
- `AsyncStream` を用いたイベント監視
- `Task` と `@MainActor` によるUIスレッドへの安全なデータバインディング
- **Key Files:** `ScaleViewModel.swift`

### 3. 信号処理 (Signal Processing)
センサーの生値は常に揺れ動いています（ノイズ）。これを不快感のない滑らかな音量変化に変換するためのアルゴリズム実装が含まれています。
- 移動平均 (Moving Average) によるスムージング
- 意図しない入力と意図的な操作を区別する「変化率 (Rate of Change)」の監視
- **Key Files:** `WeighingViewModel.swift` (ロジック参照)

### 4. macOS システム統合
アプリ内だけでなく、OS全体のマスターボリュームを制御するための `AudioToolbox` や `Core Audio` との連携、およびサンドボックス環境下での権限管理 (`entitlements`) について学べます。

## アーキテクチャ (Architecture)

このアプリは、ハードウェアからの入力をリアクティブにUIとシステム設定へ反映させる **MVVM (Model-View-ViewModel)** パターンを採用しています。

```mermaid
graph TD
    Hardware[Trackpad Force Sensors] -->|Raw Pressure Data| OMS[OpenMultitouchSupport Framework]
    OMS -->|Async Stream| VM[ScaleViewModel (ObservableObject)]

    subgraph "Application Logic"
        VM -->|Signal Processing| Logic[Smoothing & Mapping]
        Logic -->|Calculated Volume| PublishedVar[@Published volume]
    end

    PublishedVar -->|Binding| View[SwiftUI View]
    PublishedVar -->|Side Effect| AudioAPI[macOS System Audio]
````

1.  **Data Source:** `OpenMultitouchSupport` がハードウェア割り込みをフックし、タッチイベントを生成。
2.  **ViewModel:** `ScaleViewModel` が非同期ストリーム (`for await`) でデータを受け取り、ノイズ除去と数値変換（圧力 0.0〜1.0 → 音量 0.0〜100.0）を行う。
3.  **View:** SwiftUIが `@Published` プロパティの変更を検知し、画面上の「重そうなアニメーション」を描画。
4.  **System:** 同時にバックグラウンドでシステム音量を更新。

## 免責事項 (Disclaimer)

**警告:** トラックパッドに過度な重さをかけたり、鋭利な物を置いたりしないでください。トラックパッドが破損する恐れがあります。本アプリの使用によって生じたハードウェアの損傷について、開発者は一切の責任を負いません。

これはジョークです。本気で日常利用しないでください。
