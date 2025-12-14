import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import AdvancedFeature

#if os(iOS)
@Suite("UserListView Snapshot Tests")
@MainActor
struct UserListViewSnapshotTests {

    // MARK: - Loading State

    @Test("Loading state snapshot")
    func loadingState() {
        let store = Store(
            initialState: UserListFeature.State(
                isLoading: true
            )
        ) {
            UserListFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = UserListView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Users Loaded

    @Test("Users loaded snapshot")
    func usersLoaded() {
        let store = Store(
            initialState: UserListFeature.State(
                users: IdentifiedArray(uniqueElements: User.samples)
            )
        ) {
            UserListFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = UserListView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Empty State

    @Test("Empty state snapshot")
    func emptyState() {
        let store = Store(
            initialState: UserListFeature.State(
                users: []
            )
        ) {
            UserListFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = UserListView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Error State

    @Test("Error state snapshot")
    func errorState() {
        let store = Store(
            initialState: UserListFeature.State(
                errorMessage: "ネットワークエラーが発生しました"
            )
        ) {
            UserListFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = UserListView(store: store)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }
}
#endif
