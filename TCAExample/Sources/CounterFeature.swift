import ComposableArchitecture

// MARK: - TCA の基本構造
// TCA は以下の3つの要素で構成されます:
// 1. State: アプリの状態（データ）を保持
// 2. Action: ユーザーの操作やイベントを表現
// 3. Reducer: Action を受け取って State を更新するロジック

@Reducer
struct CounterFeature {
    // MARK: - State（状態）
    // アプリが保持するデータを定義します
    // @ObservableState を付けると SwiftUI が自動的に変更を検知します
    @ObservableState
    struct State: Equatable {
        var count = 0
    }

    // MARK: - Action（アクション）
    // ユーザーが行える操作を列挙型で定義します
    enum Action {
        case incrementButtonTapped  // +ボタンが押された
        case decrementButtonTapped  // -ボタンが押された
        case resetButtonTapped      // リセットボタンが押された
    }

    // MARK: - Reducer（リデューサー）
    // Action を受け取り、State を更新するロジックを書きます
    var body: some ReducerOf<Self> {
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
            }
        }
    }
}
