//
//  WeighingViewModel.swift
//  TrackWeight
//

import OpenMultitouchSupport
import SwiftUI
import Combine

@MainActor
final class WeighingViewModel: ObservableObject {
    @Published private(set) var state: WeighingState = .welcome
    @Published private(set) var currentPressure: Float = 0.0
    @Published private(set) var maxPressure: Float = 0.0
    @Published private(set) var isListening = false
    @Published private(set) var fingerTimer: Float = 0.0 // 0.0 to 1.0 for animation
    @Published private(set) var stabilityProgress: Float = 0.0
    @Published private(set) var isStabilizing: Bool = false

    private let touchProvider: TouchDataProviding
    private var task: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var baselinePressure: Float = 0.0
    private var hasDetectedFinger = false
    private var hasDetectedItem = false
    private var finalWeight: Float = 0.0
    private var pressureHistory: [Float] = []
    private var stabilityStartTime: Date?
    private var stableWeight: Float = 0.0

    // MARK: - Configuration Constants

    let fingerHoldDuration: TimeInterval = 3.0
    let historySize = 10
    let rateOfChangeThreshold: Float = 5
    let stabilityDuration: TimeInterval = 3.0
    let stabilityAnimationDelay: TimeInterval = 1.0
    let stabilityThreshold: Float = 2.0

    // MARK: - Initialization

    init(touchProvider: TouchDataProviding = OMSManager.shared) {
        self.touchProvider = touchProvider
    }

    // MARK: - Public Methods

    func startWeighing() {
        state = .waitingForFinger
        hasDetectedFinger = false
        hasDetectedItem = false
        baselinePressure = 0.0
        currentPressure = 0.0
        maxPressure = 0.0
        finalWeight = 0.0
        fingerTimer = 0.0
        stabilityProgress = 0.0
        stabilityStartTime = nil
        stableWeight = 0.0
        isStabilizing = false
        pressureHistory.removeAll()

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

    func restart() {
        stopListening()
        state = .welcome
        fingerTimer = 0.0
        stabilityProgress = 0.0
        stabilityStartTime = nil
        isStabilizing = false
    }

    // MARK: - Private Methods

    private func stopListening() {
        task?.cancel()
        timerTask?.cancel()
        if touchProvider.stopListening() {
            isListening = false
        }
    }

    private func startFingerTimer() {
        timerTask?.cancel()
        fingerTimer = 0.0

        timerTask = Task { [weak self] in
            let startTime = Date()

            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / (self?.fingerHoldDuration ?? 3.0), 1.0)

                await MainActor.run {
                    self?.fingerTimer = Float(progress)
                }

                if progress >= 1.0 {
                    await MainActor.run {
                        self?.completeFingerTimer()
                    }
                    break
                }

                try? await Task.sleep(nanoseconds: 16_666_667) // ~60fps
            }
        }
    }

    private func resetFingerTimer() {
        timerTask?.cancel()
        fingerTimer = 0.0
    }

    private func completeFingerTimer() {
        hasDetectedFinger = true
        baselinePressure = currentPressure
        state = .waitingForItem
        timerTask?.cancel()
    }

    private func startStabilityTimer(with weight: Float) {
        stabilityProgress = 0.0
        isStabilizing = true

        timerTask = Task { [weak self] in
            let animationStartTime = Date()
            let remainingDuration = (self?.stabilityDuration ?? 3.0) - (self?.stabilityAnimationDelay ?? 1.0)

            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(animationStartTime)
                let progress = min(elapsed / remainingDuration, 1.0)

                await MainActor.run {
                    self?.stabilityProgress = Float(progress)
                }

                if progress >= 1.0 {
                    await MainActor.run {
                        self?.completeWeighing()
                    }
                    break
                }

                try? await Task.sleep(nanoseconds: 16_666_667) // ~60fps
            }
        }
    }

    private func completeWeighing() {
        state = .result(weight: currentPressure)
        stopListening()
    }

    private func resetStabilityTimer() {
        stabilityStartTime = nil
        stabilityProgress = 0.0
        isStabilizing = false
        timerTask?.cancel()
    }

    private func processTouchData(_ touchData: [OMSTouchData]) {
        guard !touchData.isEmpty else {
            // Reset timer if finger is lifted during waiting
            if state == .waitingForFinger && !hasDetectedFinger {
                resetFingerTimer()
            }

            if state == .weighing {
                if hasDetectedItem && finalWeight > 0 {
                    state = .result(weight: finalWeight)
                    stopListening()
                }
            }
            return
        }

        let mainTouch = touchData.first!
        currentPressure = mainTouch.pressure

        // Add current pressure to history
        pressureHistory.append(currentPressure)
        if pressureHistory.count > historySize {
            pressureHistory.removeFirst()
        }

        // Calculate moving average
        let avgPressure = pressureHistory.reduce(0, +) / Float(pressureHistory.count)
        print("average pressure: \(avgPressure)")
        currentPressure = avgPressure

        switch state {
        case .waitingForFinger:
            if !hasDetectedFinger {
                currentPressure = mainTouch.pressure
                if fingerTimer == 0.0 {
                    startFingerTimer()
                }
            }

        case .waitingForItem:
            if hasDetectedFinger {
                // Calculate rate of change if we have enough history
                if pressureHistory.count == historySize && !hasDetectedItem {
                    let rateOfChange = pressureHistory.last! - pressureHistory.first!
                    if rateOfChange > rateOfChangeThreshold {
                        print("pressure before item: \(pressureHistory)")
                        print("Old baseline: \(baselinePressure)")
                        baselinePressure = pressureHistory.first!
                        print("New baseline: \(baselinePressure)")
                        hasDetectedItem = true
                        state = .weighing
                        resetStabilityTimer()
                    }
                }
            } else {
                state = .waitingForFinger
                pressureHistory.removeAll()
            }

        case .weighing:
            // Check if weight is stable
            let weightDifference = stabilityStartTime != nil ? abs(currentPressure - stableWeight) : 0

            if stabilityStartTime == nil {
                stabilityStartTime = Date()
                stableWeight = currentPressure
            } else if weightDifference > stabilityThreshold {
                resetStabilityTimer()
                stabilityStartTime = Date()
                stableWeight = currentPressure
            } else {
                let timeSinceStable = Date().timeIntervalSince(stabilityStartTime!)

                if timeSinceStable >= stabilityAnimationDelay && !isStabilizing {
                    startStabilityTimer(with: stableWeight)
                }
            }

        default:
            break
        }
    }

    // MARK: - Test Helpers

    #if DEBUG
    var testPressureHistory: [Float] { pressureHistory }
    var testHasDetectedFinger: Bool { hasDetectedFinger }
    var testHasDetectedItem: Bool { hasDetectedItem }
    var testBaselinePressure: Float { baselinePressure }

    func testProcessTouchData(_ touchData: [OMSTouchData]) {
        processTouchData(touchData)
    }

    func testSetState(_ newState: WeighingState) {
        state = newState
    }

    func testSetHasDetectedFinger(_ value: Bool) {
        hasDetectedFinger = value
    }

    func testAddToPressureHistory(_ pressure: Float) {
        pressureHistory.append(pressure)
        if pressureHistory.count > historySize {
            pressureHistory.removeFirst()
        }
    }

    func testClearPressureHistory() {
        pressureHistory.removeAll()
    }
    #endif

    deinit {
        task?.cancel()
        timerTask?.cancel()
    }
}
