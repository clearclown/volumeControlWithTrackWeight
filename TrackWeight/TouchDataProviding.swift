//
//  TouchDataProviding.swift
//  TrackWeight
//
//  タッチデータ提供プロトコル
//  本番環境では OMSManager、テスト環境では MockTouchDataProvider を使用
//

import Foundation
import OpenMultitouchSupport

/// タッチデータを提供するプロトコル
/// テスト可能にするためのDI用抽象化
protocol TouchDataProviding: AnyObject, Sendable {
    /// タッチデータの非同期ストリーム
    var touchDataStream: AsyncStream<[OMSTouchData]> { get }

    /// リスニング開始
    @MainActor func startListening() -> Bool

    /// リスニング停止
    @MainActor func stopListening() -> Bool
}

/// OMSManager の TouchDataProviding 準拠
extension OMSManager: TouchDataProviding {}
