import ComposableArchitecture

// MARK: - TCA の基本構造
// TCA は以下の3つの要素で構成されます:
// 1. State: アプリの状態（データ）を保持
// 2. Action: ユーザーの操作やイベントを表現
// 3. Reducer: Action を受け取って State を更新するロジック
// 4. Effect: 副作用（非同期処理、タイマー、API呼び出しなど）を扱う

@Reducer
public struct CounterFeature {
    // MARK: - State（状態）
    // アプリが保持するデータを定義します
    // @ObservableState を付けると SwiftUI が自動的に変更を検知します
    @ObservableState
    public struct State: Equatable {
        public var count = 0
        public var isTimerRunning = false  // タイマーが動作中かどうか

        public init(count: Int = 0, isTimerRunning: Bool = false) {
            self.count = count
            self.isTimerRunning = isTimerRunning
        }
    }

    // MARK: - Action（アクション）
    // ユーザーが行える操作を列挙型で定義します
    public enum Action {
        case incrementButtonTapped  // +ボタンが押された
        case decrementButtonTapped  // -ボタンが押された
        case resetButtonTapped      // リセットボタンが押された
        case timerButtonTapped      // タイマー開始/停止ボタンが押された
        case timerTick              // タイマーが1秒経過した（内部アクション）
    }

    // MARK: - CancelID
    // Effect をキャンセルするための識別子
    // 同じ ID を持つ Effect は .cancel(id:) でキャンセルできます
    private enum CancelID {
        case timer
    }

    public init() {}

    // MARK: - Reducer（リデューサー）
    // Action を受け取り、State を更新するロジックを書きます
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                // +ボタン: カウントを1増やす
                state.count += 1
                return .none  // 副作用なし

            case .decrementButtonTapped:
                // -ボタン: カウントを1減らす
                state.count -= 1
                return .none

            case .resetButtonTapped:
                // リセット: カウントを0に戻す
                state.count = 0
                return .none

            case .timerButtonTapped:
                // タイマーの開始/停止を切り替え
                state.isTimerRunning.toggle()

                if state.isTimerRunning {
                    // タイマー開始: Effect を返す
                    // Effect.run で非同期処理を実行できます
                    return .run { send in
                        // 無限ループでタイマーを実装
                        while true {
                            // 1秒待機
                            try await Task.sleep(for: .seconds(1))
                            // timerTick アクションを送信
                            await send(.timerTick)
                        }
                    }
                    // .cancellable で Effect にキャンセル ID を付与
                    // これにより後からキャンセル可能になります
                    .cancellable(id: CancelID.timer)
                } else {
                    // タイマー停止: 実行中の Effect をキャンセル
                    return .cancel(id: CancelID.timer)
                }

            case .timerTick:
                // タイマーが1秒経過: カウントを1増やす
                state.count += 1
                return .none
            }
        }
    }
}
