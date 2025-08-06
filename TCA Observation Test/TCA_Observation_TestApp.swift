import ComposableArchitecture
import SwiftUI

@main
struct TCA_Observation_TestApp: App {
  static let store = Store(
    initialState: ObservableStateSharingRootFeature.State()
  ) {
    ObservableStateSharingRootFeature()
  }
  var body: some Scene {
    WindowGroup {
      ObservableStateSharingRootView(store: Self.store)
    }
  }
}
