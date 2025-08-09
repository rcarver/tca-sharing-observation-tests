import ComposableArchitecture
import SwiftUI

@main
struct TCA_Observation_TestApp: App {
  static let vanilla = RootModel()
  static let tca = Store(
    initialState: RootFeature.State()
  ) {
    RootFeature()
  }
  static let shared = Store(
    initialState: SharedRootFeature.State()
  ) {
    SharedRootFeature()
  }
  static let prototypeShared = Store(
    initialState: IdealSharedRootFeature.State()
  ) {
    IdealSharedRootFeature()
  }
  static let observableShared = Store(
    initialState: ObservableSharedRootFeature.State()
  ) {
    ObservableSharedRootFeature()
  }
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        List {
          NavigationLink("Vanilla SwiftUI") {
            VanillaRootView(model: Self.vanilla)
          }
          NavigationLink("TCA") {
            RootView(store: Self.tca)
          }
          NavigationLink("Shared") {
            SharedRootView(store: Self.shared)
          }
          NavigationLink("Shared w/ ObservableValue") {
            ObservableSharedRootView(store: Self.observableShared)
          }
          NavigationLink("Shared Prototype using Property Wrapper to observe") {
            IdealSharedRootView(store: Self.prototypeShared)
          }
        }
      }
    }
  }
}
