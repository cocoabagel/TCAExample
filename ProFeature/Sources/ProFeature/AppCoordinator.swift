import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - 2. StackState による複雑なナビゲーション
// MARK: - 5. Scope による Reducer 合成
// AppCoordinator は複数のFeatureを統合し、StackStateでナビゲーションを管理します

// MARK: - HomeFeature (ダッシュボード)

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        // @Shared を使って設定を他のFeatureと共有
        @Shared(.isDarkMode) public var isDarkMode: Bool
        @Shared(.appSettings) public var appSettings: AppSettings

        public init() {}
    }

    public enum Action {
        case settingsTapped
        case searchTapped
        case timerTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .settingsTapped, .searchTapped, .timerTapped:
                // 親（AppCoordinator）でハンドリング
                return .none
            }
        }
    }
}

// MARK: - HomeView

public struct HomeView: View {
    let store: StoreOf<HomeFeature>

    public init(store: StoreOf<HomeFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            // ユーザー情報セクション
            Section {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Text(String(store.appSettings.userName.prefix(1)))
                                .font(.title)
                                .foregroundStyle(.blue)
                        }

                    VStack(alignment: .leading) {
                        Text("こんにちは、\(store.appSettings.userName)さん")
                            .font(.headline)
                        Text("今日の目標: \(store.appSettings.dailyGoal)分")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // メニューセクション
            Section("機能") {
                Button {
                    store.send(.searchTapped)
                } label: {
                    Label("検索", systemImage: "magnifyingglass")
                }

                Button {
                    store.send(.timerTapped)
                } label: {
                    Label("タイマー", systemImage: "timer")
                }

                Button {
                    store.send(.settingsTapped)
                } label: {
                    Label("設定", systemImage: "gear")
                }
            }

            // 現在のモード表示
            Section("状態") {
                HStack {
                    Text("ダークモード")
                    Spacer()
                    Text(store.isDarkMode ? "ON" : "OFF")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("通知")
                    Spacer()
                    Text(store.appSettings.notificationsEnabled ? "有効" : "無効")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("ホーム")
    }
}

// MARK: - AppCoordinator

@Reducer
public struct AppCoordinator {
    @ObservableState
    public struct State {
        // 2. StackState: NavigationStack のパスを管理
        public var path = StackState<Path.State>()

        // 5. Scope: 子Featureの状態を保持
        public var home = HomeFeature.State()
        public var settings = SettingsFeature.State()
        public var search = SearchFeature.State()
        public var timer = TimerFeature.State()

        public init() {}
    }

    public enum Action {
        // NavigationStackのアクション
        case path(StackActionOf<Path>)

        // 5. Scope: 子Featureのアクション
        case home(HomeFeature.Action)
        case settings(SettingsFeature.Action)
        case search(SearchFeature.Action)
        case timer(TimerFeature.Action)
    }

    // 2. StackState: ナビゲーション先の定義
    @Reducer
    public enum Path {
        case settings(SettingsFeature)
        case search(SearchFeature)
        case timer(TimerFeature)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        // 5. Scope: 各子Featureを合成
        // Scope を使うことで、子Featureの状態とアクションを親で管理

        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Scope(state: \.search, action: \.search) {
            SearchFeature()
        }

        Scope(state: \.timer, action: \.timer) {
            TimerFeature()
        }

        Reduce { state, action in
            switch action {
            // HomeFeatureからの画面遷移
            case .home(.settingsTapped):
                state.path.append(.settings(state.settings))
                return .none

            case .home(.searchTapped):
                state.path.append(.search(state.search))
                return .none

            case .home(.timerTapped):
                state.path.append(.timer(state.timer))
                return .none

            // パス内の状態変更を本体に同期
            case .path(.element(id: _, action: .settings)):
                // SettingsFeatureの変更はScopeで同期されるため特別な処理は不要
                return .none

            case .path(.element(id: _, action: .search)):
                return .none

            case .path(.element(id: _, action: .timer)):
                return .none

            case .path:
                return .none

            case .settings, .search, .timer:
                // Scopeで処理される
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

// MARK: - AppCoordinatorView

public struct AppCoordinatorView: View {
    @Bindable var store: StoreOf<AppCoordinator>

    public init(store: StoreOf<AppCoordinator>) {
        self.store = store
    }

    public var body: some View {
        // 2. StackState: NavigationStack と連携
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            HomeView(store: store.scope(state: \.home, action: \.home))
        } destination: { store in
            switch store.case {
            case .settings(let settingsStore):
                SettingsView(store: settingsStore)
            case .search(let searchStore):
                SearchView(store: searchStore)
            case .timer(let timerStore):
                TimerView(store: timerStore)
            }
        }
        // @Shared のダークモード設定を適用
        .preferredColorScheme(store.settings.isDarkMode ? .dark : .light)
    }
}

// MARK: - ProFeatureのエクスポート

public struct ProFeatureView: View {
    public init() {}

    public var body: some View {
        AppCoordinatorView(
            store: Store(initialState: AppCoordinator.State()) {
                AppCoordinator()
            }
        )
    }
}

#Preview {
    ProFeatureView()
}
