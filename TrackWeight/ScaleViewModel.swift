//
//  ScaleViewModel.swift
//  TrackWeight
//

import OpenMultitouchSupport
import SwiftUI
import Combine

@MainActor
final class ScaleViewModel: ObservableObject {
    @Published private(set) var currentWeight: Float = 0.0
    @Published private(set) var zeroOffset: Float = 0.0
    @Published private(set) var isListening = false
    @Published private(set) var hasTouch = false

    private let touchProvider: TouchDataProviding
    private var task: Task<Void, Never>?
    private var rawWeight: Float = 0.0

    // MARK: - Initialization

    /// 依存性注入対応イニシャライザ
    /// - Parameter touchProvider: タッチデータプロバイダー（デフォルト: OMSManager.shared）
    init(touchProvider: TouchDataProviding = OMSManager.shared) {
        self.touchProvider = touchProvider
    }

    // MARK: - Public Methods

    func startListening() {
        if touchProvider.startListening() {
            isListening = true
        }

        task = Task { [weak self, touchProvider] in
            for await touchData in touchProvider.touchDataStream {
                await MainActor.run {
                    self?.processTouchData(touchData)
                }
            }
        }
    }

    func stopListening() {
        task?.cancel()
        if touchProvider.stopListening() {
            isListening = false
            hasTouch = false
            currentWeight = 0.0
        }
    }

    func zeroScale() {
        if hasTouch {
            zeroOffset = rawWeight
        }
    }

    // MARK: - Private Methods

    private func processTouchData(_ touchData: [OMSTouchData]) {
        if touchData.isEmpty {
            hasTouch = false
            currentWeight = 0.0
            zeroOffset = 0.0  // Reset zero when finger is lifted
        } else {
            hasTouch = true
            rawWeight = touchData.first?.pressure ?? 0.0
            currentWeight = max(0, rawWeight - zeroOffset)
        }
    }

    // MARK: - Test Helpers (internal visibility for testing)

    #if DEBUG
    /// テスト用: 現在の生の重量値を取得
    var testRawWeight: Float { rawWeight }

    /// テスト用: タッチデータを直接処理
    func testProcessTouchData(_ touchData: [OMSTouchData]) {
        processTouchData(touchData)
    }
    #endif

    deinit {
        task?.cancel()
        // Note: touchProvider.stopListening() は deinit では呼ばない
        // MainActor の制約があるため、stopListening() で明示的に停止すること
    }
}
