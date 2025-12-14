import ComposableArchitecture
import SwiftUI

// MARK: - View（ビュー）
// TCA では Store を通じて State を読み取り、Action を送信します

struct CounterView: View {
    // Store: State と Action を管理するコンテナ
    let store: StoreOf<CounterFeature>

    var body: some View {
        VStack(spacing: 24) {
            Text("TCA カウンター")
                .font(.title)
                .fontWeight(.bold)

            // State の count を表示
            Text("\(store.count)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(store.count >= 0 ? .primary : .red)

            HStack(spacing: 20) {
                // -ボタン: Action を送信
                Button {
                    store.send(.decrementButtonTapped)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 48))
                }

                // リセットボタン
                Button {
                    store.send(.resetButtonTapped)
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 48))
                }

                // +ボタン: Action を送信
                Button {
                    store.send(.incrementButtonTapped)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                }
            }

            // 学習用の説明
            VStack(alignment: .leading, spacing: 8) {
                Text("TCA の流れ:")
                    .font(.headline)
                Text("1. ボタンをタップ → Action を送信")
                Text("2. Reducer が Action を処理")
                Text("3. State が更新される")
                Text("4. View が自動的に再描画")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

#Preview {
    CounterView(
        store: Store(initialState: CounterFeature.State()) {
            CounterFeature()
        }
    )
}
