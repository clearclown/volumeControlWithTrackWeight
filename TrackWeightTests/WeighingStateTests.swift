//
//  WeighingStateTests.swift
//  TrackWeightTests
//

import XCTest
@testable import TrackWeight

final class WeighingStateTests: XCTestCase {

    // MARK: - Equatable Tests

    func testWelcomeStateEquality() {
        XCTAssertEqual(WeighingState.welcome, WeighingState.welcome)
    }

    func testWaitingForFingerStateEquality() {
        XCTAssertEqual(WeighingState.waitingForFinger, WeighingState.waitingForFinger)
    }

    func testWaitingForItemStateEquality() {
        XCTAssertEqual(WeighingState.waitingForItem, WeighingState.waitingForItem)
    }

    func testWeighingStateEquality() {
        XCTAssertEqual(WeighingState.weighing, WeighingState.weighing)
    }

    func testResultStateEqualityWithSameWeight() {
        XCTAssertEqual(WeighingState.result(weight: 50.0), WeighingState.result(weight: 50.0))
    }

    func testResultStateInequalityWithDifferentWeight() {
        XCTAssertNotEqual(WeighingState.result(weight: 50.0), WeighingState.result(weight: 100.0))
    }

    func testDifferentStatesAreNotEqual() {
        XCTAssertNotEqual(WeighingState.welcome, WeighingState.waitingForFinger)
        XCTAssertNotEqual(WeighingState.waitingForFinger, WeighingState.waitingForItem)
        XCTAssertNotEqual(WeighingState.waitingForItem, WeighingState.weighing)
        XCTAssertNotEqual(WeighingState.weighing, WeighingState.result(weight: 0))
    }
}
