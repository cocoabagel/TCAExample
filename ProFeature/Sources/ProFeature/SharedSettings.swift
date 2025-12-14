import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - 1. @Shared による状態共有と永続化
// @Shared を使うと、複数のFeature間で状態を共有し、
// AppStorage や FileStorage で自動的に永続化できます

// MARK: - 共有する設定データ

public struct AppSettings: Codable, Equatable, Sendable {
    public var userName: String
    public var notificationsEnabled: Bool
    public var dailyGoal: Int

    public init(
        userName: String = "ゲスト",
        notificationsEnabled: Bool = true,
        dailyGoal: Int = 10
    ) {
        self.userName = userName
        self.notificationsEnabled = notificationsEnabled
        self.dailyGoal = dailyGoal
    }
}

// MARK: - SharedKey の定義

extension SharedKey where Self == AppStorageKey<Bool>.Default {
    /// ダークモード設定（AppStorageで永続化）
    public static var isDarkMode: Self {
        Self[.appStorage("isDarkMode"), default: false]
    }
}

extension SharedKey where Self == FileStorageKey<AppSettings>.Default {
    /// アプリ設定（ファイルで永続化）
    public static var appSettings: Self {
        Self[.fileStorage(.documentsDirectory.appending(path: "appSettings.json")), default: AppSettings()]
    }
}

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        // @Shared: 複数のFeature間で共有され、永続化される
        @Shared(.isDarkMode) public var isDarkMode: Bool
        @Shared(.appSettings) public var appSettings: AppSettings

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case incrementGoalTapped
        case decrementGoalTapped
        case resetSettingsTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .incrementGoalTapped:
                // @Shared の値を変更するには withLock を使用
                state.$appSettings.withLock { $0.dailyGoal += 1 }
                return .none

            case .decrementGoalTapped:
                state.$appSettings.withLock { settings in
                    if settings.dailyGoal > 1 {
                        settings.dailyGoal -= 1
                    }
                }
                return .none

            case .resetSettingsTapped:
                state.$appSettings.withLock { $0 = AppSettings() }
                state.$isDarkMode.withLock { $0 = false }
                return .none
            }
        }
    }
}

// MARK: - SettingsView

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        Form {
            Section("表示設定") {
                Toggle("ダークモード", isOn: $store.isDarkMode)
            }

            Section("プロフィール") {
                TextField("ユーザー名", text: $store.appSettings.userName)
                Toggle("通知を有効にする", isOn: $store.appSettings.notificationsEnabled)
            }

            Section("目標設定") {
                Stepper(
                    "1日の目標: \(store.appSettings.dailyGoal)",
                    onIncrement: { store.send(.incrementGoalTapped) },
                    onDecrement: { store.send(.decrementGoalTapped) }
                )
            }

            Section {
                Button(role: .destructive) {
                    store.send(.resetSettingsTapped)
                } label: {
                    HStack {
                        Spacer()
                        Text("設定をリセット")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("設定")
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            }
        )
    }
}
