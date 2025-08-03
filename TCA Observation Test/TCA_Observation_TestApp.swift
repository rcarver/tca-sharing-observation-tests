import ComposableArchitecture
import SwiftUI

@main
struct TCA_Observation_TestApp: App {
  static let store = Store(
    initialState: IdealSharedRootFeature.State()
  ) {
    IdealSharedRootFeature()
  }
    var body: some Scene {
        WindowGroup {
          IdealSharedRootView(store: Self.store)
        }
    }
}
