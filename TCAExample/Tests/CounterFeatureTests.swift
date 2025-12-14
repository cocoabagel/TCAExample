import ComposableArchitecture
import Testing
@testable import TCAExample

// MARK: - TCA テストのメリット
// 1. TestStore を使うと、Action を送信した後の State の変化を厳密に検証できる
// 2. 予期しない State の変化があるとテストが失敗する（バグを早期発見）
// 3. 副作用（Effect）も完全にテスト可能
// 4. UIに依存せずロジックだけをテストできる

@Suite("CounterFeature Tests")
@MainActor
struct CounterFeatureTests {

    // MARK: - インクリメントのテスト
    @Test("Increment button increases count by 1")
    func increment() async {
        // TestStore を作成
        // 初期状態: count = 0
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }

        // Action を送信し、State の変化を検証
        await store.send(.incrementButtonTapped) {
            // この中で「期待する State の変化」を記述
            // count が 0 → 1 に変わることを検証
            $0.count = 1
        }
    }

    // MARK: - デクリメントのテスト
    @Test("Decrement button decreases count by 1")
    func decrement() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }

        await store.send(.decrementButtonTapped) {
            // count が 0 → -1 に変わることを検証
            $0.count = -1
        }
    }

    // MARK: - リセットのテスト
    @Test("Reset button sets count to 0")
    func reset() async {
        // 初期状態を count = 5 に設定
        let store = TestStore(initialState: CounterFeature.State(count: 5)) {
            CounterFeature()
        }

        await store.send(.resetButtonTapped) {
            // count が 5 → 0 に変わることを検証
            $0.count = 0
        }
    }

    // MARK: - 連続操作のテスト
    @Test("Multiple actions work correctly in sequence")
    func multipleActions() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }

        // 複数の Action を順番に送信
        // TCA のテストでは、各 Action 後の State を厳密に検証する

        await store.send(.incrementButtonTapped) {
            $0.count = 1  // 0 → 1
        }

        await store.send(.incrementButtonTapped) {
            $0.count = 2  // 1 → 2
        }

        await store.send(.incrementButtonTapped) {
            $0.count = 3  // 2 → 3
        }

        await store.send(.decrementButtonTapped) {
            $0.count = 2  // 3 → 2
        }

        await store.send(.resetButtonTapped) {
            $0.count = 0  // 2 → 0
        }
    }

    // MARK: - 負の値のテスト
    @Test("Count can go negative")
    func negativeCount() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }

        await store.send(.decrementButtonTapped) {
            $0.count = -1
        }

        await store.send(.decrementButtonTapped) {
            $0.count = -2
        }

        await store.send(.decrementButtonTapped) {
            $0.count = -3
        }
    }

    // MARK: - State の初期値のテスト
    @Test("Initial state has count of 0")
    func initialState() {
        let state = CounterFeature.State()
        #expect(state.count == 0)
    }

    // MARK: - カスタム初期値のテスト
    @Test("Custom initial state works correctly")
    func customInitialState() async {
        // 初期値を 100 に設定
        let store = TestStore(initialState: CounterFeature.State(count: 100)) {
            CounterFeature()
        }

        await store.send(.incrementButtonTapped) {
            $0.count = 101  // 100 → 101
        }
    }
}

// MARK: - TCA テストの重要なポイント
/*
 1. 【厳密な State 検証】
    store.send のクロージャ内で State の変化を明示的に書く必要がある。
    予期しない変化があるとテストが失敗する。

 2. 【副作用のテスト】
    今回のカウンターは副作用がないが、API呼び出しなどの副作用も
    TestStore でモック化してテスト可能。

 3. 【UI非依存】
    View をインスタンス化せずにロジックだけをテストできる。
    テストが高速で安定する。

 4. 【ドキュメントとしての価値】
    テストコードが「この Action を送ると State がこう変わる」という
    仕様書の役割も果たす。
 */
