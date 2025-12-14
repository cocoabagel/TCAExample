import Foundation

// MARK: - User Model
// APIから取得するユーザーデータ

public struct User: Equatable, Identifiable, Sendable {
    public let id: Int
    public var name: String
    public var email: String
    public var isActive: Bool

    public init(id: Int, name: String, email: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.email = email
        self.isActive = isActive
    }
}

// MARK: - Sample Data

extension User {
    static let samples: [User] = [
        User(id: 1, name: "田中 太郎", email: "tanaka@example.com", isActive: true),
        User(id: 2, name: "佐藤 花子", email: "sato@example.com", isActive: true),
        User(id: 3, name: "鈴木 一郎", email: "suzuki@example.com", isActive: false),
        User(id: 4, name: "高橋 美咲", email: "takahashi@example.com", isActive: true),
        User(id: 5, name: "伊藤 健太", email: "ito@example.com", isActive: true),
    ]
}
