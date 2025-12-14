import ComposableArchitecture
import Testing
@testable import ProFeature

@Suite("TimerFeature Tests")
struct TimerFeatureTests {
    @Test("タイマー開始で isRunning が true になる")
    @MainActor
    func startTimerSetsRunning() async {
        let clock = TestClock()

        let store = TestStore(
            initialState: TimerFeature.State()
        ) {
            TimerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.startTapped) {
            $0.isRunning = true
        }

        // タイマーをキャンセル（クリーンアップ）
        await store.send(.stopTapped) {
            $0.isRunning = false
        }
    }

    @Test("タイマー停止で isRunning が false になる")
    @MainActor
    func stopTimerSetsNotRunning() async {
        let clock = TestClock()

        var state = TimerFeature.State()
        state.isRunning = true

        let store = TestStore(
            initialState: state
        ) {
            TimerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.stopTapped) {
            $0.isRunning = false
        }
    }

    @Test("タイマーTickで経過時間が増加する")
    @MainActor
    func timerTickIncrementsElapsedSeconds() async {
        let clock = TestClock()

        let store = TestStore(
            initialState: TimerFeature.State()
        ) {
            TimerFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.startTapped) {
            $0.isRunning = true
        }

        // 1秒進める
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTick) {
            $0.elapsedSeconds = 1
        }

        // もう1秒進める
        await clock.advance(by: .seconds(1))
        await store.receive(.timerTick) {
            $0.elapsedSeconds = 2
        }

        // 停止
        await store.send(.stopTapped) {
            $0.isRunning = false
        }
    }

    @Test("リセットで全ての状態が初期化される")
    @MainActor
    func resetClearsAllState() async {
        var state = TimerFeature.State()
        state.elapsedSeconds = 120
        state.isRunning = true
        state.laps = [30, 60, 90]

        let store = TestStore(
            initialState: state
        ) {
            TimerFeature()
        }

        await store.send(.resetTapped) {
            $0.isRunning = false
            $0.elapsedSeconds = 0
            $0.laps = []
        }
    }

    @Test("ラップ追加で現在の時間が記録される")
    @MainActor
    func lapAddsCurrentTime() async {
        var state = TimerFeature.State()
        state.elapsedSeconds = 45
        state.isRunning = true

        let store = TestStore(
            initialState: state
        ) {
            TimerFeature()
        }

        await store.send(.lapTapped) {
            $0.laps = [45]
        }
    }

    @Test("formattedTime が正しくフォーマットされる")
    func formattedTimeIsCorrect() {
        var state = TimerFeature.State()

        state.elapsedSeconds = 0
        #expect(state.formattedTime == "00:00")

        state.elapsedSeconds = 59
        #expect(state.formattedTime == "00:59")

        state.elapsedSeconds = 60
        #expect(state.formattedTime == "01:00")

        state.elapsedSeconds = 125
        #expect(state.formattedTime == "02:05")

        state.elapsedSeconds = 3661
        #expect(state.formattedTime == "61:01")
    }

    @Test("progress が目標に対する進捗を正しく計算する")
    func progressCalculatesCorrectly() {
        var state = TimerFeature.State()

        // 目標10分のうち0秒 = 0%
        state.elapsedSeconds = 0
        #expect(state.progress == 0.0)

        // 目標10分のうち5分 = 50%
        state.elapsedSeconds = 300
        #expect(state.progress == 0.5)

        // 目標10分のうち10分 = 100%
        state.elapsedSeconds = 600
        #expect(state.progress == 1.0)

        // 目標を超えても100%で止まる
        state.elapsedSeconds = 1200
        #expect(state.progress == 1.0)
    }
}
