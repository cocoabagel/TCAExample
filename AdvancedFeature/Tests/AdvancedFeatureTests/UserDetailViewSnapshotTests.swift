import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import AdvancedFeature

#if os(iOS)
@Suite("UserDetailView Snapshot Tests")
@MainActor
struct UserDetailViewSnapshotTests {

    // MARK: - Normal State

    @Test("Normal state snapshot")
    func normalState() {
        let store = Store(
            initialState: UserDetailFeature.State(user: User.samples[0])
        ) {
            UserDetailFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = NavigationStack {
            UserDetailView(store: store)
        }

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Inactive User

    @Test("Inactive user snapshot")
    func inactiveUser() {
        let inactiveUser = User.samples.first { !$0.isActive }!
        let store = Store(
            initialState: UserDetailFeature.State(user: inactiveUser)
        ) {
            UserDetailFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = NavigationStack {
            UserDetailView(store: store)
        }

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Editing State

    @Test("Editing state snapshot")
    func editingState() {
        var state = UserDetailFeature.State(user: User.samples[0])
        state.isEditing = true
        state.editedName = "編集中の名前"
        state.editedEmail = "editing@example.com"

        let store = Store(initialState: state) {
            UserDetailFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = NavigationStack {
            UserDetailView(store: store)
        }

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Saving State

    @Test("Saving state snapshot")
    func savingState() {
        var state = UserDetailFeature.State(user: User.samples[0])
        state.isSaving = true

        let store = Store(initialState: state) {
            UserDetailFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = NavigationStack {
            UserDetailView(store: store)
        }

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    // MARK: - Error State

    @Test("Error state snapshot")
    func errorState() {
        var state = UserDetailFeature.State(user: User.samples[0])
        state.errorMessage = "保存に失敗しました"

        let store = Store(initialState: state) {
            UserDetailFeature()
        } withDependencies: {
            $0.apiClient = .previewValue
        }
        let view = NavigationStack {
            UserDetailView(store: store)
        }

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }
}
#endif
