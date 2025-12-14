import ComposableArchitecture
import SwiftUI

// MARK: - View（ビュー）
// TCA では Store を通じて State を読み取り、Action を送信します

public struct CounterView: View {
    // Store: State と Action を管理するコンテナ
    let store: StoreOf<CounterFeature>

    public init(store: StoreOf<CounterFeature>) {
        self.store = store
    }

    public var body: some View {
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

            // タイマーボタン: Effect のデモ
            Button {
                store.send(.timerButtonTapped)
            } label: {
                HStack {
                    Image(systemName: store.isTimerRunning ? "stop.fill" : "play.fill")
                    Text(store.isTimerRunning ? "タイマー停止" : "タイマー開始")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(store.isTimerRunning ? Color.red : Color.green)
                .clipShape(Capsule())
            }

            // 学習用の説明
            VStack(alignment: .leading, spacing: 8) {
                Text("Effect（副作用）の例:")
                    .font(.headline)
                Text("1. タイマー開始 → Effect.run で非同期処理")
                Text("2. 1秒ごとに timerTick Action を送信")
                Text("3. タイマー停止 → .cancel で Effect をキャンセル")
                Text("4. CancelID でどの Effect を止めるか識別")
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
