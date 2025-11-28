//
//  MockTouchDataProvider.swift
//  TrackWeightTests
//

import Foundation
import OpenMultitouchSupport
@testable import TrackWeight

/// テスト用モックプロバイダー
/// TouchDataProviding に準拠し、テストで制御可能なタッチデータを提供
final class MockTouchDataProvider: TouchDataProviding, @unchecked Sendable {
    private var continuation: AsyncStream<[OMSTouchData]>.Continuation?
    private(set) var isListening = false
    private(set) var startListeningCallCount = 0
    private(set) var stopListeningCallCount = 0

    /// リスニング開始時の戻り値（テストで変更可能）
    var startListeningResult = true

    /// リスニング停止時の戻り値（テストで変更可能）
    var stopListeningResult = true

    var touchDataStream: AsyncStream<[OMSTouchData]> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
        }
    }

    @MainActor
    func startListening() -> Bool {
        startListeningCallCount += 1
        if startListeningResult {
            isListening = true
        }
        return startListeningResult
    }

    @MainActor
    func stopListening() -> Bool {
        stopListeningCallCount += 1
        if stopListeningResult {
            isListening = false
            continuation?.finish()
        }
        return stopListeningResult
    }

    // MARK: - テストヘルパーメソッド

    /// 指定したタッチデータをストリームに送信
    func sendTouchData(_ touchData: [OMSTouchData]) {
        continuation?.yield(touchData)
    }

    /// タッチなし状態を送信（指を離した）
    func sendNoTouch() {
        continuation?.yield([])
    }

    /// ストリームを終了
    func finish() {
        continuation?.finish()
    }

    /// 状態をリセット
    func reset() {
        isListening = false
        startListeningCallCount = 0
        stopListeningCallCount = 0
        startListeningResult = true
        stopListeningResult = true
    }
}

// MARK: - テスト用 OMSTouchData 拡張

/// OMSTouchData のイニシャライザが internal なため、
/// メモリ操作を使用してテスト用インスタンスを作成
extension OMSTouchData {
    /// テスト用モックデータを作成
    /// - Parameter pressure: 圧力値
    /// - Returns: 指定した圧力値を持つ OMSTouchData
    static func mock(pressure: Float) -> OMSTouchData {
        // ゼロ初期化されたメモリを確保
        let ptr = UnsafeMutablePointer<OMSTouchData>.allocate(capacity: 1)
        defer { ptr.deallocate() }

        // メモリをゼロで初期化
        memset(ptr, 0, MemoryLayout<OMSTouchData>.size)

        // ゼロ初期化された構造体をコピー
        var data = ptr.pointee

        // public var プロパティを設定（ネストした構造体もゼロ初期化済み）
        data.id = 0
        // position は内部で x, y がゼロ初期化済み
        data.position.x = 0.5
        data.position.y = 0.5
        data.total = pressure
        data.pressure = pressure
        // axis は内部で major, minor がゼロ初期化済み
        data.axis.major = 10
        data.axis.minor = 10
        data.angle = 0
        data.density = 1.0
        data.state = .touching
        data.timestamp = ""

        return data
    }
}
