import ComposableArchitecture
import SwiftUI

// MARK: - UserDetailFeature
// 子Feature: ユーザー詳細画面
// 親（UserListFeature）から呼び出される

@Reducer
public struct UserDetailFeature {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var user: User
        public var isEditing: Bool = false
        public var editedName: String = ""
        public var editedEmail: String = ""
        public var isSaving: Bool = false
        public var errorMessage: String?

        public init(user: User) {
            self.user = user
            self.editedName = user.name
            self.editedEmail = user.email
        }
    }

    // MARK: - Action

    public enum Action: BindableAction {
        // BindableAction: @Bindable で双方向バインディングを可能にする
        case binding(BindingAction<State>)

        case editButtonTapped
        case cancelButtonTapped
        case saveButtonTapped
        case saveResponse(Result<User, Error>)
        case deleteButtonTapped
        case deleteResponse(Result<Void, Error>)

        // 親に通知するためのデリゲートアクション
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case userUpdated(User)
            case userDeleted(Int)
        }
    }

    // MARK: - Dependencies

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.dismiss) var dismiss  // NavigationStackからの戻りに使用

    public init() {}

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .editButtonTapped:
                state.isEditing = true
                state.editedName = state.user.name
                state.editedEmail = state.user.email
                return .none

            case .cancelButtonTapped:
                state.isEditing = false
                state.errorMessage = nil
                return .none

            case .saveButtonTapped:
                state.isSaving = true
                state.errorMessage = nil

                // Swift 6: varはEffect内でキャプチャできないのでletで宣言
                let updatedUser = User(
                    id: state.user.id,
                    name: state.editedName,
                    email: state.editedEmail,
                    isActive: state.user.isActive
                )

                // Swift 6: Dependencyをローカル変数に取り出してからEffect内で使用
                let apiClient = apiClient
                return .run { send in
                    await send(.saveResponse(
                        Result { try await apiClient.updateUser(updatedUser) }
                    ))
                }

            case .saveResponse(.success(let user)):
                state.isSaving = false
                state.isEditing = false
                state.user = user
                // 親に更新を通知
                return .send(.delegate(.userUpdated(user)))

            case .saveResponse(.failure(let error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none

            case .deleteButtonTapped:
                let userId = state.user.id
                let apiClient = apiClient
                return .run { send in
                    await send(.deleteResponse(
                        Result { try await apiClient.deleteUser(userId) }
                    ))
                }

            case .deleteResponse(.success):
                let userId = state.user.id
                let dismiss = dismiss
                return .run { send in
                    // 親に削除を通知してから画面を閉じる
                    await send(.delegate(.userDeleted(userId)))
                    await dismiss()
                }

            case .deleteResponse(.failure(let error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .delegate:
                // 親で処理される
                return .none
            }
        }
    }
}

// MARK: - View

public struct UserDetailView: View {
    @Bindable var store: StoreOf<UserDetailFeature>

    public init(store: StoreOf<UserDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        Form {
            // ユーザー情報セクション
            Section("ユーザー情報") {
                if store.isEditing {
                    TextField("名前", text: $store.editedName)
                    TextField("メールアドレス", text: $store.editedEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                } else {
                    LabeledContent("名前", value: store.user.name)
                    LabeledContent("メールアドレス", value: store.user.email)
                    LabeledContent("ステータス") {
                        Text(store.user.isActive ? "アクティブ" : "非アクティブ")
                            .foregroundStyle(store.user.isActive ? .green : .secondary)
                    }
                }
            }

            // エラーメッセージ
            if let errorMessage = store.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            // 削除ボタン（編集中でない場合のみ）
            if !store.isEditing {
                Section {
                    Button(role: .destructive) {
                        store.send(.deleteButtonTapped)
                    } label: {
                        HStack {
                            Spacer()
                            Text("ユーザーを削除")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(store.user.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.isEditing {
                    HStack {
                        Button("キャンセル") {
                            store.send(.cancelButtonTapped)
                        }
                        Button("保存") {
                            store.send(.saveButtonTapped)
                        }
                        .disabled(store.isSaving)
                    }
                } else {
                    Button("編集") {
                        store.send(.editButtonTapped)
                    }
                }
            }
        }
        .overlay {
            if store.isSaving {
                ProgressView("保存中...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserDetailView(
            store: Store(initialState: UserDetailFeature.State(user: User.samples[0])) {
                UserDetailFeature()
            }
        )
    }
}
