//
//  ScaleViewModelTests.swift
//  TrackWeightTests
//

import XCTest
import OpenMultitouchSupport
@testable import TrackWeight

@MainActor
final class ScaleViewModelTests: XCTestCase {
    var mockProvider: MockTouchDataProvider!
    var viewModel: ScaleViewModel!

    override func setUp() {
        super.setUp()
        mockProvider = MockTouchDataProvider()
        viewModel = ScaleViewModel(touchProvider: mockProvider)
    }

    override func tearDown() {
        viewModel = nil
        mockProvider = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialCurrentWeightIsZero() {
        XCTAssertEqual(viewModel.currentWeight, 0.0)
    }

    func testInitialZeroOffsetIsZero() {
        XCTAssertEqual(viewModel.zeroOffset, 0.0)
    }

    func testInitialIsListeningIsFalse() {
        XCTAssertFalse(viewModel.isListening)
    }

    func testInitialHasTouchIsFalse() {
        XCTAssertFalse(viewModel.hasTouch)
    }

    // MARK: - Listening Tests

    func testStartListeningSetsIsListeningTrue() {
        viewModel.startListening()
        XCTAssertTrue(viewModel.isListening)
        XCTAssertEqual(mockProvider.startListeningCallCount, 1)
    }

    func testStartListeningFailsWhenProviderFails() {
        mockProvider.startListeningResult = false
        viewModel.startListening()
        XCTAssertFalse(viewModel.isListening)
    }

    func testStopListeningSetsIsListeningFalse() {
        viewModel.startListening()
        viewModel.stopListening()
        XCTAssertFalse(viewModel.isListening)
        XCTAssertEqual(mockProvider.stopListeningCallCount, 1)
    }

    func testStopListeningResetsState() {
        viewModel.startListening()
        // シミュレート: タッチデータを処理
        let touchData = OMSTouchData.mock(pressure: 50.0)
        viewModel.testProcessTouchData([touchData])

        XCTAssertTrue(viewModel.hasTouch)

        viewModel.stopListening()

        XCTAssertFalse(viewModel.hasTouch)
        XCTAssertEqual(viewModel.currentWeight, 0.0)
    }

    // MARK: - Touch Detection Tests

    func testTouchDataSetsHasTouchTrue() {
        let touchData = OMSTouchData.mock(pressure: 30.0)
        viewModel.testProcessTouchData([touchData])

        XCTAssertTrue(viewModel.hasTouch)
    }

    func testEmptyTouchDataSetsHasTouchFalse() {
        // まずタッチを検知させる
        let touchData = OMSTouchData.mock(pressure: 30.0)
        viewModel.testProcessTouchData([touchData])
        XCTAssertTrue(viewModel.hasTouch)

        // 指を離す
        viewModel.testProcessTouchData([])

        XCTAssertFalse(viewModel.hasTouch)
        XCTAssertEqual(viewModel.currentWeight, 0.0)
        XCTAssertEqual(viewModel.zeroOffset, 0.0)
    }

    // MARK: - Zero Calibration Tests

    func testZeroScaleSetsOffset() {
        // タッチデータを処理
        let touchData = OMSTouchData.mock(pressure: 30.0)
        viewModel.testProcessTouchData([touchData])

        // ゼロ補正を実行
        viewModel.zeroScale()

        XCTAssertEqual(viewModel.zeroOffset, 30.0)
    }

    func testZeroScaleDoesNothingWithoutTouch() {
        // タッチなしの状態
        XCTAssertFalse(viewModel.hasTouch)

        // ゼロ補正を試みる
        viewModel.zeroScale()

        XCTAssertEqual(viewModel.zeroOffset, 0.0)
    }

    func testCurrentWeightSubtractsZeroOffset() {
        // 最初のタッチ: 圧力20.0
        let touchData1 = OMSTouchData.mock(pressure: 20.0)
        viewModel.testProcessTouchData([touchData1])
        viewModel.zeroScale()

        // オフセット後のタッチ: 圧力50.0
        let touchData2 = OMSTouchData.mock(pressure: 50.0)
        viewModel.testProcessTouchData([touchData2])

        // 50.0 - 20.0 = 30.0
        XCTAssertEqual(viewModel.currentWeight, 30.0)
    }

    func testCurrentWeightNeverNegative() {
        // 最初のタッチ: 圧力30.0
        let touchData1 = OMSTouchData.mock(pressure: 30.0)
        viewModel.testProcessTouchData([touchData1])
        viewModel.zeroScale()

        // オフセット後のタッチ: 圧力10.0（オフセットより小さい）
        let touchData2 = OMSTouchData.mock(pressure: 10.0)
        viewModel.testProcessTouchData([touchData2])

        // max(0, 10.0 - 30.0) = 0.0
        XCTAssertEqual(viewModel.currentWeight, 0.0)
    }

    // MARK: - Finger Lift Reset Tests

    func testZeroOffsetResetsOnFingerLift() {
        // タッチしてゼロ補正
        let touchData = OMSTouchData.mock(pressure: 20.0)
        viewModel.testProcessTouchData([touchData])
        viewModel.zeroScale()
        XCTAssertEqual(viewModel.zeroOffset, 20.0)

        // 指を離す
        viewModel.testProcessTouchData([])

        XCTAssertEqual(viewModel.zeroOffset, 0.0)
    }

    // MARK: - Pressure Reading Tests

    func testPressureReadingFromTouchData() {
        let touchData = OMSTouchData.mock(pressure: 75.5)
        viewModel.testProcessTouchData([touchData])

        XCTAssertEqual(viewModel.currentWeight, 75.5, accuracy: 0.01)
    }

    func testMultipleTouchesUsesFirstTouch() {
        let touch1 = OMSTouchData.mock(pressure: 50.0)
        let touch2 = OMSTouchData.mock(pressure: 100.0)
        viewModel.testProcessTouchData([touch1, touch2])

        // 最初のタッチの圧力を使用
        XCTAssertEqual(viewModel.currentWeight, 50.0)
    }
}
