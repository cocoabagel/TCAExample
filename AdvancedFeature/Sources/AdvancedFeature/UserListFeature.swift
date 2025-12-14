import ComposableArchitecture
import SwiftUI

// MARK: - UserListFeature
// 親Feature: ユーザー一覧画面
// Navigation と 子Feature（UserDetailFeature）を管理

@Reducer
public struct UserListFeature {
    // MARK: - State

    @ObservableState
    public struct State {
        public var users: IdentifiedArrayOf<User> = []
        public var isLoading: Bool = false
        public var errorMessage: String?

        // Navigation: 詳細画面への遷移を管理
        // @Presents で optional な子 State を表現
        @Presents public var destination: Destination.State?

        public init(
            users: IdentifiedArrayOf<User> = [],
            isLoading: Bool = false,
            errorMessage: String? = nil,
            destination: Destination.State? = nil
        ) {
            self.users = users
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.destination = destination
        }

    }

    // MARK: - Destination（遷移先の定義）
    // 複数の遷移先がある場合は enum で定義

    @Reducer
    public enum Destination {
        case detail(UserDetailFeature)
        case alert(AlertState<Alert>)

        @CasePathable
        public enum Alert: Equatable {
            case confirmDelete(userId: Int)
        }
    }

    // MARK: - Action

    public enum Action {
        case onAppear
        case fetchUsers
        case fetchUsersResponse(Result<[User], Error>)
        case userTapped(User)
        case refreshButtonTapped
        case deleteSwipeAction(userId: Int)

        // 遷移先のアクションを受け取る
        case destination(PresentationAction<Destination.Action>)
    }

    // MARK: - Dependencies

    @Dependency(\.apiClient) var apiClient

    public init() {}

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 初回表示時にデータ取得
                guard state.users.isEmpty else { return .none }
                return .send(.fetchUsers)

            case .fetchUsers:
                state.isLoading = true
                state.errorMessage = nil
                let apiClient = apiClient
                return .run { send in
                    await send(.fetchUsersResponse(
                        Result { try await apiClient.fetchUsers() }
                    ))
                }

            case .fetchUsersResponse(.success(let users)):
                state.isLoading = false
                // IdentifiedArray に変換（ID で効率的にアクセス可能）
                state.users = IdentifiedArray(uniqueElements: users)
                return .none

            case .fetchUsersResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .userTapped(let user):
                // 詳細画面へ遷移
                state.destination = .detail(UserDetailFeature.State(user: user))
                return .none

            case .refreshButtonTapped:
                return .send(.fetchUsers)

            case .deleteSwipeAction(let userId):
                // 削除確認アラートを表示
                state.destination = .alert(
                    AlertState {
                        TextState("削除確認")
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDelete(userId: userId)) {
                            TextState("削除")
                        }
                        ButtonState(role: .cancel) {
                            TextState("キャンセル")
                        }
                    } message: {
                        TextState("このユーザーを削除しますか？")
                    }
                )
                return .none

            // MARK: - Destination Actions

            case .destination(.presented(.detail(.delegate(.userUpdated(let user))))):
                // 子から更新通知を受け取り、リストを更新
                state.users[id: user.id] = user
                return .none

            case .destination(.presented(.detail(.delegate(.userDeleted(let userId))))):
                // 子から削除通知を受け取り、リストから削除
                state.users.remove(id: userId)
                return .none

            case .destination(.presented(.alert(.confirmDelete(let userId)))):
                // アラートで削除が確認された
                state.users.remove(id: userId)
                return .none

            case .destination:
                // その他の destination アクションは無視
                return .none
            }
        }
        // 遷移先の Reducer を統合
        .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - View

public struct UserListView: View {
    @Bindable var store: StoreOf<UserListFeature>

    public init(store: StoreOf<UserListFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.users.isEmpty {
                    // 初回ロード中
                    ProgressView("読み込み中...")
                } else if let errorMessage = store.errorMessage, store.users.isEmpty {
                    // エラー表示
                    ContentUnavailableView {
                        Label("エラー", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("再試行") {
                            store.send(.refreshButtonTapped)
                        }
                    }
                } else {
                    // ユーザーリスト
                    List {
                        ForEach(store.users) { user in
                            UserRowView(user: user)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.userTapped(user))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        store.send(.deleteSwipeAction(userId: user.id))
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .refreshable {
                        store.send(.refreshButtonTapped)
                    }
                }
            }
            .navigationTitle("ユーザー一覧")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            store.send(.refreshButtonTapped)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            // Navigation: 詳細画面への遷移
            .navigationDestination(
                item: $store.scope(state: \.destination?.detail, action: \.destination.detail)
            ) { detailStore in
                UserDetailView(store: detailStore)
            }
            // Alert の表示
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - UserRowView

struct UserRowView: View {
    let user: User

    var body: some View {
        HStack {
            // アバター
            Circle()
                .fill(user.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(user.name.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(user.isActive ? .green : .secondary)
                }

            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // ステータスインジケーター
            Circle()
                .fill(user.isActive ? .green : .gray)
                .frame(width: 8, height: 8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    UserListView(
        store: Store(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
    )
}
