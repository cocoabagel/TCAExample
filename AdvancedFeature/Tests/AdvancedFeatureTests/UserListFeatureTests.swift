import Testing

@testable import AdvancedFeature

@Suite("AdvancedFeature Tests")
struct AdvancedFeatureTests {

    // MARK: - User Model Tests

    @Test("User model has correct properties")
    func userModelProperties() {
        let user = User(id: 1, name: "テスト太郎", email: "test@example.com", isActive: true)

        #expect(user.id == 1)
        #expect(user.name == "テスト太郎")
        #expect(user.email == "test@example.com")
        #expect(user.isActive == true)
    }

    @Test("User samples are available")
    func userSamplesExist() {
        #expect(User.samples.count == 5)
        #expect(User.samples[0].name == "田中 太郎")
    }

    // MARK: - APIError Tests

    @Test("APIError has correct descriptions")
    func apiErrorDescriptions() {
        #expect(APIError.notFound.localizedDescription == "データが見つかりませんでした")
        #expect(APIError.networkError.localizedDescription == "ネットワークエラーが発生しました")
        #expect(APIError.serverError("test").localizedDescription == "サーバーエラー: test")
    }

    // MARK: - State Initialization Tests

    @Test("UserListFeature.State initializes correctly")
    func userListStateInit() {
        let state = UserListFeature.State()

        #expect(state.users.isEmpty)
        #expect(state.isLoading == false)
        #expect(state.errorMessage == nil)
        #expect(state.destination == nil)
    }

    @Test("UserDetailFeature.State initializes with user")
    func userDetailStateInit() {
        let user = User.samples[0]
        let state = UserDetailFeature.State(user: user)

        #expect(state.user == user)
        #expect(state.isEditing == false)
        #expect(state.editedName == user.name)
        #expect(state.editedEmail == user.email)
    }
}
