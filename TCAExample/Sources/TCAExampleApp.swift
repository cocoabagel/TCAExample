import ComposableArchitecture
import SwiftUI

@main
struct TCAExampleApp: App {
    // アプリ全体で使う Store を作成
    // static let にすることで、アプリのライフサイクル中ずっと保持されます
    static let store = Store(initialState: CounterFeature.State()) {
        CounterFeature()
    }

    var body: some Scene {
        WindowGroup {
            CounterView(store: TCAExampleApp.store)
        }
    }
}
