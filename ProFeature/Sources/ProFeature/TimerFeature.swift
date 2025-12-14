import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - 6. Long-running Effects
// タイマーやストリーム監視など、長時間実行されるEffectの実装方法を示します

@Reducer
public struct TimerFeature {
    // キャンセルID
    enum CancelID {
        case timer
    }

    @ObservableState
    public struct State: Equatable {
        public var elapsedSeconds: Int = 0
        public var isRunning: Bool = false
        public var laps: [Int] = []

        // @Shared を使って目標設定を他のFeatureと共有
        @Shared(.appSettings) public var appSettings: AppSettings

        public var formattedTime: String {
            let minutes = elapsedSeconds / 60
            let seconds = elapsedSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        public var progress: Double {
            guard appSettings.dailyGoal > 0 else { return 0 }
            return min(Double(elapsedSeconds) / Double(appSettings.dailyGoal * 60), 1.0)
        }

        public init() {}
    }

    public enum Action {
        case startTapped
        case stopTapped
        case resetTapped
        case lapTapped
        case timerTick
    }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startTapped:
                state.isRunning = true

                // Long-running Effect: タイマーを開始
                // AsyncStream を使って継続的にイベントを発行
                let clock = clock
                return .run { send in
                    // for await を使った無限ループでタイマーを実現
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)

            case .stopTapped:
                state.isRunning = false
                // タイマーをキャンセル
                return .cancel(id: CancelID.timer)

            case .resetTapped:
                state.isRunning = false
                state.elapsedSeconds = 0
                state.laps = []
                return .cancel(id: CancelID.timer)

            case .lapTapped:
                state.laps.append(state.elapsedSeconds)
                return .none

            case .timerTick:
                state.elapsedSeconds += 1
                return .none
            }
        }
    }
}

// MARK: - TimerView

public struct TimerView: View {
    let store: StoreOf<TimerFeature>

    public init(store: StoreOf<TimerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 24) {
            // 進捗リング
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: store.progress)
                    .stroke(
                        store.progress >= 1.0 ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: store.progress)

                VStack {
                    Text(store.formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                    Text("目標: \(store.appSettings.dailyGoal)分")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 250, height: 250)
            .padding()

            // コントロールボタン
            HStack(spacing: 24) {
                Button {
                    store.send(.resetTapped)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .disabled(!store.isRunning && store.elapsedSeconds == 0)

                Button {
                    if store.isRunning {
                        store.send(.stopTapped)
                    } else {
                        store.send(.startTapped)
                    }
                } label: {
                    Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(store.isRunning ? Color.orange : Color.green)
                        .clipShape(Circle())
                }

                Button {
                    store.send(.lapTapped)
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .disabled(!store.isRunning)
            }

            // ラップタイム
            if !store.laps.isEmpty {
                List {
                    ForEach(Array(store.laps.enumerated().reversed()), id: \.offset) { index, seconds in
                        HStack {
                            Text("ラップ \(index + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatTime(seconds))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 200)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("タイマー")
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    NavigationStack {
        TimerView(
            store: Store(initialState: TimerFeature.State()) {
                TimerFeature()
            }
        )
    }
}
