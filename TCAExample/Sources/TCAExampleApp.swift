import AdvancedFeature
import ComposableArchitecture
import CounterFeature
import SwiftUI

@main
struct TCAExampleApp: App {
    // 各Feature用のStoreを作成
    static let counterStore = Store(initialState: CounterFeature.State()) {
        CounterFeature()
    }

    static let userListStore = Store(initialState: UserListFeature.State()) {
        UserListFeature()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                // タブ1: シンプルなカウンター（TCA基本）
                Tab("カウンター", systemImage: "number.circle") {
                    NavigationStack {
                        CounterView(store: TCAExampleApp.counterStore)
                            .navigationTitle("TCA 基本")
                    }
                }

                // タブ2: ユーザー一覧（TCA応用）
                // Navigation, Dependency, 親子連携を含む
                Tab("ユーザー", systemImage: "person.2") {
                    UserListView(store: TCAExampleApp.userListStore)
                }
            }
        }
    }
}
