import ComposableArchitecture
import Foundation
import Testing
@testable import ProFeature

// MARK: - 4. TestStore による網羅的テスト
// TestStoreを使うと、状態変化を完全に検証し、
// 予期しないActionがあればテストが失敗します

@Suite("SearchFeature Tests")
struct SearchFeatureTests {
    @Test("検索クエリ入力でローディング状態になる")
    @MainActor
    func searchQueryStartsLoading() async {
        // テスト用のClockを作成（時間を制御可能）
        let clock = TestClock()

        let store = TestStore(
            initialState: SearchFeature.State()
        ) {
            SearchFeature()
        } withDependencies: {
            // テスト用の依存性を注入
            $0.continuousClock = clock
            $0.searchClient.search = { _ in [] }
        }

        // アクションを送信し、状態変化を検証
        await store.send(.searchQueryChanged("Swift")) {
            // クロージャ内で期待する状態変化を記述
            $0.query = "Swift"
            $0.isSearching = true
        }

        // Effect をキャンセル（空クエリを送信）
        await store.send(.searchQueryChanged("")) {
            $0.query = ""
            $0.results = []
            $0.isSearching = false
        }
    }

    @Test("空のクエリで検索がキャンセルされる")
    @MainActor
    func emptyQueryCancelsSearch() async {
        let clock = TestClock()

        let store = TestStore(
            initialState: SearchFeature.State()
        ) {
            SearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.searchClient.search = { _ in [] }
        }

        // まず検索を開始
        await store.send(.searchQueryChanged("Swift")) {
            $0.query = "Swift"
            $0.isSearching = true
        }

        // 空のクエリを送信
        await store.send(.searchQueryChanged("")) {
            $0.query = ""
            $0.results = []
            $0.isSearching = false
        }
    }

    @Test("検索成功時に結果が設定される")
    @MainActor
    func searchReturnsResults() async {
        let clock = TestClock()
        let expectedResults = [
            SearchResult(title: "Result 1", description: "Description 1"),
            SearchResult(title: "Result 2", description: "Description 2"),
        ]

        let store = TestStore(
            initialState: SearchFeature.State()
        ) {
            SearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.searchClient.search = { _ in expectedResults }
        }

        await store.send(.searchQueryChanged("test")) {
            $0.query = "test"
            $0.isSearching = true
        }

        // TestClockを進めてデバウンスを完了
        await clock.advance(by: .milliseconds(300))

        // 検索レスポンスを受信
        await store.receive(\.searchResponse.success) {
            $0.isSearching = false
            $0.results = expectedResults
        }
    }

    @Test("検索失敗時にエラーメッセージが設定される")
    @MainActor
    func searchFailureShowsError() async {
        let clock = TestClock()
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "テストエラー" }
        }

        let store = TestStore(
            initialState: SearchFeature.State()
        ) {
            SearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.searchClient.search = { _ in throw TestError() }
        }

        await store.send(.searchQueryChanged("test")) {
            $0.query = "test"
            $0.isSearching = true
        }

        await clock.advance(by: .milliseconds(300))

        await store.receive(\.searchResponse.failure) {
            $0.isSearching = false
            $0.errorMessage = "テストエラー"
        }
    }

    @Test("cancelInFlightで古い検索がキャンセルされる")
    @MainActor
    func cancelInFlightCancelsPreviousSearch() async {
        let clock = TestClock()

        // LockIsolated を使ってスレッドセーフにカウント
        let searchCount = LockIsolated(0)

        let store = TestStore(
            initialState: SearchFeature.State()
        ) {
            SearchFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.searchClient.search = { query in
                searchCount.withValue { $0 += 1 }
                let count = searchCount.value
                return [SearchResult(title: query, description: "Count: \(count)")]
            }
        }

        // 最初の検索
        await store.send(.searchQueryChanged("A")) {
            $0.query = "A"
            $0.isSearching = true
        }

        // デバウンス完了前に新しい検索
        await clock.advance(by: .milliseconds(100))

        await store.send(.searchQueryChanged("AB")) {
            $0.query = "AB"
            // isSearchingは既にtrue
        }

        // デバウンス完了前にさらに新しい検索
        await clock.advance(by: .milliseconds(100))

        await store.send(.searchQueryChanged("ABC")) {
            $0.query = "ABC"
        }

        // 最後の検索のデバウンス完了
        await clock.advance(by: .milliseconds(300))

        // 最後の検索結果のみ受信（前の検索はキャンセルされた）
        // non-exhaustiveモードで確認
        store.exhaustivity = .off
        await store.receive(\.searchResponse.success)

        // searchは1回しか呼ばれない（前の2回はキャンセルされた）
        #expect(searchCount.value == 1)
        #expect(store.state.results.count == 1)
        #expect(store.state.results.first?.title == "ABC")
    }

    @Test("clearResultsTappedで状態がリセットされる")
    @MainActor
    func clearResultsResetsState() async {
        var initialState = SearchFeature.State()
        initialState.query = "test"
        initialState.results = [
            SearchResult(title: "Test", description: "Description"),
        ]

        let store = TestStore(
            initialState: initialState
        ) {
            SearchFeature()
        } withDependencies: {
            $0.searchClient.search = { _ in [] }
        }

        await store.send(.clearResultsTapped) {
            $0.query = ""
            $0.results = []
        }
    }
}
