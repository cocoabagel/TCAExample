import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - 3. Effect のキャンセルと ID 管理
// 検索機能を例に、デバウンスとキャンセルの実装方法を示します

// MARK: - SearchClient (Dependency)

@DependencyClient
public struct SearchClient: Sendable {
    public var search: @Sendable (String) async throws -> [SearchResult]
}

public struct SearchResult: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String

    public init(id: UUID = UUID(), title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}

extension SearchClient: DependencyKey {
    public static let liveValue = SearchClient { query in
        // 実際のAPI呼び出しをシミュレート
        try await Task.sleep(for: .milliseconds(500))

        // サンプルデータを返す
        let allResults = [
            SearchResult(title: "SwiftUI入門", description: "SwiftUIの基本を学ぶ"),
            SearchResult(title: "TCA実践ガイド", description: "The Composable Architectureの実践的な使い方"),
            SearchResult(title: "Swift Concurrency", description: "async/awaitの完全ガイド"),
            SearchResult(title: "UIKit to SwiftUI", description: "UIKitからSwiftUIへの移行"),
            SearchResult(title: "Core Data入門", description: "データ永続化の基本"),
        ]

        if query.isEmpty {
            return []
        }

        return allResults.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }
    }

    public static let previewValue = SearchClient { query in
        try await Task.sleep(for: .milliseconds(200))
        return [
            SearchResult(title: "プレビュー結果1", description: "検索: \(query)"),
            SearchResult(title: "プレビュー結果2", description: "検索: \(query)"),
        ]
    }

    public static let testValue = SearchClient()
}

extension DependencyValues {
    public var searchClient: SearchClient {
        get { self[SearchClient.self] }
        set { self[SearchClient.self] = newValue }
    }
}

// MARK: - SearchFeature

@Reducer
public struct SearchFeature {
    // キャンセルIDの定義
    // Effect をキャンセルする際に使用する識別子
    enum CancelID {
        case search
    }

    @ObservableState
    public struct State: Equatable {
        public var query: String = ""
        public var results: [SearchResult] = []
        public var isSearching: Bool = false
        public var errorMessage: String?

        // @Shared を使って他のFeatureと検索履歴を共有
        @Shared(.appSettings) public var appSettings: AppSettings

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case searchQueryChanged(String)
        case searchResponse(Result<[SearchResult], Error>)
        case cancelSearchTapped
        case clearResultsTapped
        case resultTapped(SearchResult)
    }

    @Dependency(\.searchClient) var searchClient
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .searchQueryChanged(let query):
                state.query = query
                state.errorMessage = nil

                // 空のクエリの場合は検索をキャンセルして結果をクリア
                guard !query.isEmpty else {
                    state.results = []
                    state.isSearching = false
                    return .cancel(id: CancelID.search)
                }

                state.isSearching = true

                // デバウンス: 300ms待ってから検索を実行
                // cancelInFlight: true により、新しい検索が来たら古いものはキャンセル
                let searchClient = searchClient
                let clock = clock
                return .run { send in
                    // デバウンス待機
                    try await clock.sleep(for: .milliseconds(300))
                    // 検索実行
                    await send(.searchResponse(
                        Result { try await searchClient.search(query) }
                    ))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .searchResponse(.success(let results)):
                state.isSearching = false
                state.results = results
                return .none

            case .searchResponse(.failure(let error)):
                state.isSearching = false
                state.errorMessage = error.localizedDescription
                return .none

            case .cancelSearchTapped:
                state.isSearching = false
                // 実行中の検索をキャンセル
                return .cancel(id: CancelID.search)

            case .clearResultsTapped:
                state.query = ""
                state.results = []
                return .cancel(id: CancelID.search)

            case .resultTapped:
                // 結果タップ時の処理（親に委譲することも可能）
                return .none
            }
        }
    }
}

// MARK: - SearchView

public struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>

    public init(store: StoreOf<SearchFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("検索...", text: $store.query.sending(\.searchQueryChanged))
                    .textFieldStyle(.plain)

                if store.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                if !store.query.isEmpty {
                    Button {
                        store.send(.clearResultsTapped)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding()

            // エラーメッセージ
            if let error = store.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            }

            // 検索結果
            if store.results.isEmpty && !store.query.isEmpty && !store.isSearching {
                ContentUnavailableView(
                    "結果なし",
                    systemImage: "magnifyingglass",
                    description: Text("「\(store.query)」に一致する結果が見つかりませんでした")
                )
            } else {
                List(store.results) { result in
                    Button {
                        store.send(.resultTapped(result))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.headline)
                            Text(result.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("検索")
    }
}

#Preview {
    NavigationStack {
        SearchView(
            store: Store(initialState: SearchFeature.State()) {
                SearchFeature()
            }
        )
    }
}
