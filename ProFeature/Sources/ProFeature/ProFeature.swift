// ProFeature モジュール
// TCAの高度な機能を実装したサンプル
//
// 実装されている機能:
// 1. @Shared - 複数Feature間の状態共有と永続化 (SharedSettings.swift)
// 2. StackState - 複雑なナビゲーション (AppCoordinator.swift)
// 3. Effect キャンセル - デバウンスとキャンセル (SearchFeature.swift)
// 4. TestStore - 網羅的なテスト (Tests/ProFeatureTests/)
// 5. Scope - Reducer合成 (AppCoordinator.swift)
// 6. Long-running Effects - タイマー等の継続的なEffect (TimerFeature.swift)

import ComposableArchitecture
import SwiftUI

// 公開API
@_exported import struct ComposableArchitecture.Shared
@_exported import struct ComposableArchitecture.StackState
