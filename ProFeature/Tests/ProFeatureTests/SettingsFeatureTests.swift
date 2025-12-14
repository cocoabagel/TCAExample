import ComposableArchitecture
import Foundation
import Testing
@testable import ProFeature

@Suite("SettingsFeature Tests")
struct SettingsFeatureTests {
    @Test("目標増加ボタンで dailyGoal が増加する")
    @MainActor
    func incrementGoalIncreasesValue() async {
        let store = TestStore(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        }

        let initialGoal = store.state.appSettings.dailyGoal

        await store.send(.incrementGoalTapped) {
            $0.$appSettings.withLock { $0.dailyGoal = initialGoal + 1 }
        }
    }

    @Test("目標減少ボタンで dailyGoal が減少する")
    @MainActor
    func decrementGoalDecreasesValue() async {
        let store = TestStore(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        }

        // 目標を増やしておく
        await store.send(.incrementGoalTapped) {
            $0.$appSettings.withLock { $0.dailyGoal = 11 }
        }

        await store.send(.decrementGoalTapped) {
            $0.$appSettings.withLock { $0.dailyGoal = 10 }
        }
    }

    @Test("目標が1未満にならない")
    @MainActor
    func goalDoesNotGoBelowOne() async {
        var initialState = SettingsFeature.State()
        initialState.$appSettings.withLock { $0.dailyGoal = 1 }

        let store = TestStore(
            initialState: initialState
        ) {
            SettingsFeature()
        }

        // 減少しても1のまま（状態変化なし）
        await store.send(.decrementGoalTapped)
    }

    @Test("設定リセットで全てがデフォルト値に戻る")
    @MainActor
    func resetSettingsRestoresDefaults() async {
        var initialState = SettingsFeature.State()
        initialState.$appSettings.withLock { settings in
            settings.userName = "テストユーザー"
            settings.dailyGoal = 30
            settings.notificationsEnabled = false
        }
        initialState.$isDarkMode.withLock { $0 = true }

        let store = TestStore(
            initialState: initialState
        ) {
            SettingsFeature()
        }

        await store.send(.resetSettingsTapped) {
            $0.$appSettings.withLock { $0 = AppSettings() }
            $0.$isDarkMode.withLock { $0 = false }
        }

        #expect(store.state.appSettings.userName == "ゲスト")
        #expect(store.state.appSettings.dailyGoal == 10)
        #expect(store.state.appSettings.notificationsEnabled == true)
    }
}

@Suite("AppSettings Model Tests")
struct AppSettingsTests {
    @Test("デフォルト値が正しく設定される")
    func defaultValuesAreCorrect() {
        let settings = AppSettings()

        #expect(settings.userName == "ゲスト")
        #expect(settings.notificationsEnabled == true)
        #expect(settings.dailyGoal == 10)
    }

    @Test("カスタム値で初期化できる")
    func canInitializeWithCustomValues() {
        let settings = AppSettings(
            userName: "カスタム",
            notificationsEnabled: false,
            dailyGoal: 20
        )

        #expect(settings.userName == "カスタム")
        #expect(settings.notificationsEnabled == false)
        #expect(settings.dailyGoal == 20)
    }

    @Test("Codableでエンコード/デコードできる")
    func canEncodeAndDecode() throws {
        let original = AppSettings(
            userName: "テスト",
            notificationsEnabled: false,
            dailyGoal: 15
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)

        #expect(decoded == original)
    }
}
