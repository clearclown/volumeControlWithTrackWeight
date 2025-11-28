//
//  WeighingViewModelTests.swift
//  TrackWeightTests
//

import XCTest
import OpenMultitouchSupport
@testable import TrackWeight

@MainActor
final class WeighingViewModelTests: XCTestCase {
    var mockProvider: MockTouchDataProvider!
    var viewModel: WeighingViewModel!

    override func setUp() {
        super.setUp()
        mockProvider = MockTouchDataProvider()
        viewModel = WeighingViewModel(touchProvider: mockProvider)
    }

    override func tearDown() {
        viewModel = nil
        mockProvider = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialStateIsWelcome() {
        XCTAssertEqual(viewModel.state, .welcome)
    }

    func testInitialCurrentPressureIsZero() {
        XCTAssertEqual(viewModel.currentPressure, 0.0)
    }

    func testInitialIsListeningIsFalse() {
        XCTAssertFalse(viewModel.isListening)
    }

    func testInitialFingerTimerIsZero() {
        XCTAssertEqual(viewModel.fingerTimer, 0.0)
    }

    func testInitialStabilityProgressIsZero() {
        XCTAssertEqual(viewModel.stabilityProgress, 0.0)
    }

    // MARK: - State Transition Tests

    func testStartWeighingTransitionsToWaitingForFinger() {
        viewModel.startWeighing()
        XCTAssertEqual(viewModel.state, .waitingForFinger)
        XCTAssertTrue(viewModel.isListening)
    }

    func testStartWeighingResetsAllValues() {
        // 何かの状態にしておく
        viewModel.startWeighing()

        // 再度開始
        viewModel.startWeighing()

        XCTAssertEqual(viewModel.state, .waitingForFinger)
        XCTAssertEqual(viewModel.currentPressure, 0.0)
        XCTAssertEqual(viewModel.fingerTimer, 0.0)
        XCTAssertEqual(viewModel.stabilityProgress, 0.0)
        XCTAssertFalse(viewModel.isStabilizing)
    }

    func testRestartResetsToWelcome() {
        viewModel.startWeighing()
        viewModel.restart()

        XCTAssertEqual(viewModel.state, .welcome)
        XCTAssertFalse(viewModel.isListening)
        XCTAssertEqual(viewModel.fingerTimer, 0.0)
        XCTAssertEqual(viewModel.stabilityProgress, 0.0)
    }

    // MARK: - Configuration Constants Tests

    func testHistorySizeConstant() {
        XCTAssertEqual(viewModel.historySize, 10)
    }

    func testRateOfChangeThresholdConstant() {
        XCTAssertEqual(viewModel.rateOfChangeThreshold, 5.0)
    }

    func testStabilityThresholdConstant() {
        XCTAssertEqual(viewModel.stabilityThreshold, 2.0)
    }

    func testFingerHoldDurationConstant() {
        XCTAssertEqual(viewModel.fingerHoldDuration, 3.0)
    }

    func testStabilityDurationConstant() {
        XCTAssertEqual(viewModel.stabilityDuration, 3.0)
    }

    // MARK: - Moving Average Tests

    func testPressureHistoryAccumulates() {
        viewModel.startWeighing()
        viewModel.testSetHasDetectedFinger(true)
        viewModel.testSetState(.waitingForItem)

        // 圧力履歴を追加
        for i in 1...5 {
            viewModel.testAddToPressureHistory(Float(i * 10))
        }

        XCTAssertEqual(viewModel.testPressureHistory.count, 5)
    }

    func testPressureHistoryLimitedToHistorySize() {
        viewModel.startWeighing()

        // historySize より多くの値を追加
        for i in 1...15 {
            viewModel.testAddToPressureHistory(Float(i))
        }

        XCTAssertEqual(viewModel.testPressureHistory.count, viewModel.historySize)
    }

    func testMovingAverageCalculation() {
        // 履歴に追加: 10, 20, 30, 40, 50 → 平均 = 30
        viewModel.testClearPressureHistory()
        for value: Float in [10, 20, 30, 40, 50] {
            viewModel.testAddToPressureHistory(value)
        }

        let history = viewModel.testPressureHistory
        let average = history.reduce(0, +) / Float(history.count)

        XCTAssertEqual(average, 30.0)
    }

    // MARK: - Rate of Change Detection Tests

    func testRateOfChangeDetectsItem() {
        viewModel.startWeighing()
        viewModel.testSetState(.waitingForItem)
        viewModel.testSetHasDetectedFinger(true)
        viewModel.testClearPressureHistory()

        // historySize 分の履歴を作成（変化率が閾値を超える）
        // 最初: 10, 最後: 20 → 変化率 = 10 > 5(閾値)
        for i in 0..<viewModel.historySize {
            let pressure = Float(10 + i)  // 10, 11, 12, ... 19
            viewModel.testAddToPressureHistory(pressure)
        }

        // 変化率を計算
        let history = viewModel.testPressureHistory
        let rateOfChange = history.last! - history.first!

        XCTAssertGreaterThan(rateOfChange, viewModel.rateOfChangeThreshold)
    }

    func testRateOfChangeBelowThreshold() {
        viewModel.testClearPressureHistory()

        // 変化率が閾値以下の履歴を作成
        // 全て同じ値 → 変化率 = 0
        for _ in 0..<viewModel.historySize {
            viewModel.testAddToPressureHistory(50.0)
        }

        let history = viewModel.testPressureHistory
        let rateOfChange = history.last! - history.first!

        XCTAssertLessThanOrEqual(rateOfChange, viewModel.rateOfChangeThreshold)
    }

    // MARK: - Stability Detection Tests

    func testWeightIsStableWithinThreshold() {
        // 基準重量と比較して差が閾値以内
        let baseWeight: Float = 50.0
        let currentWeight: Float = 51.5  // 差 = 1.5 < 2.0

        let difference = abs(currentWeight - baseWeight)

        XCTAssertLessThanOrEqual(difference, viewModel.stabilityThreshold)
    }

    func testWeightIsUnstableOutsideThreshold() {
        // 基準重量と比較して差が閾値を超える
        let baseWeight: Float = 50.0
        let currentWeight: Float = 53.0  // 差 = 3.0 > 2.0

        let difference = abs(currentWeight - baseWeight)

        XCTAssertGreaterThan(difference, viewModel.stabilityThreshold)
    }

    // MARK: - Touch Data Processing Tests

    func testEmptyTouchDataInWaitingForFinger() {
        viewModel.startWeighing()
        XCTAssertEqual(viewModel.state, .waitingForFinger)

        // 指を離す（空のデータ）
        viewModel.testProcessTouchData([])

        // fingerTimer がリセットされるはず（タイマーが動いていれば）
        XCTAssertEqual(viewModel.fingerTimer, 0.0)
    }

    // MARK: - Edge Cases

    func testProcessTouchDataWithValidPressure() {
        viewModel.startWeighing()

        let touchData = OMSTouchData.mock(pressure: 50.0)
        viewModel.testProcessTouchData([touchData])

        // 圧力が設定されていることを確認
        XCTAssertGreaterThan(viewModel.currentPressure, 0.0)
    }

    func testMultipleStartWeighingCalls() {
        viewModel.startWeighing()
        viewModel.startWeighing()
        viewModel.startWeighing()

        // 複数回呼んでもクラッシュせず、正しい状態
        XCTAssertEqual(viewModel.state, .waitingForFinger)
        XCTAssertTrue(viewModel.isListening)
    }

    func testRestartFromVariousStates() {
        // welcomeから
        viewModel.restart()
        XCTAssertEqual(viewModel.state, .welcome)

        // waitingForFingerから
        viewModel.startWeighing()
        viewModel.restart()
        XCTAssertEqual(viewModel.state, .welcome)

        // weighingから（状態を手動で設定）
        viewModel.startWeighing()
        viewModel.testSetState(.weighing)
        viewModel.restart()
        XCTAssertEqual(viewModel.state, .welcome)
    }
}
