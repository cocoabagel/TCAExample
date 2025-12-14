import ComposableArchitecture
import Foundation

// MARK: - APIClient
// TCA の Dependency（依存性注入）の例
// 実際のAPIクライアントとモック実装を切り替え可能にする

@DependencyClient
public struct APIClient: Sendable {
    // ユーザー一覧を取得
    public var fetchUsers: @Sendable () async throws -> [User]
    // ユーザー詳細を取得
    public var fetchUser: @Sendable (Int) async throws -> User
    // ユーザーを更新
    public var updateUser: @Sendable (User) async throws -> User
    // ユーザーを削除
    public var deleteUser: @Sendable (Int) async throws -> Void
}

// MARK: - DependencyKey
// Dependency として登録するためのキー

extension APIClient: DependencyKey {
    // 本番環境で使用される実装
    // 今回はモックAPIとして実装（実際はURLSessionを使う）
    public static let liveValue: APIClient = {
        APIClient(
            fetchUsers: {
                // ネットワーク遅延をシミュレート
                try await Task.sleep(for: .seconds(1))
                return User.samples
            },
            fetchUser: { id in
                try await Task.sleep(for: .milliseconds(500))
                guard let user = User.samples.first(where: { $0.id == id }) else {
                    throw APIError.notFound
                }
                return user
            },
            updateUser: { user in
                try await Task.sleep(for: .milliseconds(500))
                return user
            },
            deleteUser: { _ in
                try await Task.sleep(for: .milliseconds(500))
            }
        )
    }()

    // テスト時に使用される実装（即座に空の結果を返す）
    public static let testValue = APIClient()

    // プレビュー時に使用される実装
    public static let previewValue: APIClient = {
        APIClient(
            fetchUsers: { User.samples },
            fetchUser: { id in User.samples.first { $0.id == id }! },
            updateUser: { $0 },
            deleteUser: { _ in }
        )
    }()
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// MARK: - API Errors

public enum APIError: Error, Equatable, LocalizedError {
    case notFound
    case networkError
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "データが見つかりませんでした"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        }
    }
}
