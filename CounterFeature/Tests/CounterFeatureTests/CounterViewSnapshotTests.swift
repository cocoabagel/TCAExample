import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import CounterFeature

#if os(iOS)
@Suite("CounterView Snapshot Tests")
@MainActor
struct CounterViewSnapshotTests {

    // MARK: - Initial State

    @Test("Initial state snapshot")
    func initialState() {
        let store = Store(initialState: CounterFeature.State()) {
            CounterFeature()
        }
        let view = CounterView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Positive Count

    @Test("Positive count snapshot")
    func positiveCount() {
        let store = Store(initialState: CounterFeature.State(count: 42)) {
            CounterFeature()
        }
        let view = CounterView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Negative Count

    @Test("Negative count snapshot")
    func negativeCount() {
        let store = Store(initialState: CounterFeature.State(count: -5)) {
            CounterFeature()
        }
        let view = CounterView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Timer Running

    @Test("Timer running snapshot")
    func timerRunning() {
        let store = Store(initialState: CounterFeature.State(count: 10, isTimerRunning: true)) {
            CounterFeature()
        }
        let view = CounterView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }
}
#endif
