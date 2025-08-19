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
      HStack(alignment: .top) {
        Sample("Vanilla SwiftUI") {
          VanillaRootView(model: Self.vanilla)
        } description: {
          Text("View model using @Perceptible property wrapper (for shouldNotifyObservers)")
          Text("Exhibits ideal view updates")
        }
        Sample("TCA") {
          RootView(store: Self.tca)
        } description: {
          Text("TCA features using @ObservableState")
          Text("Exhibits ideal view updates > 1.21.1")
          Text("Previously, noop caused updates")
        }
        Sample("TCA + Shared") {
          SharedRootView(store: Self.shared)
        } description: {
          Text("Typical use of @Shared value between TCA features")
          Text("Exhibits worst-case view updates")
        }
        Sample("TCA + Shared + ObservableValue") {
          ObservableSharedRootView(store: Self.observableShared)
        } description: {
          Text("@Shared with @ObservableValue (and shouldNotifyObservers support)")
          Text("Exhibits ideal view updates")
        }
//        Sample("Shared Prototype using Property Wrapper to observe") {
//          IdealSharedRootView(store: Self.prototypeShared)
//        } description: {
//          Text("Prototype of @Shared using custom property observation")
//          Text("Exhibits ideal view updates")
//        }
      }
      .padding()
    }
  }
}

struct Sample<Content: View, Description: View>: View {
  let name: String
  let content: Content
  let description: Description
  init(
    _ name: String,
    @ViewBuilder content: () -> Content,
    @ViewBuilder description: () -> Description
  ) {
    self.name = name
    self.content = content()
    self.description = description()
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(name)
        .font(.headline)
      content
      VStack(alignment: .leading, spacing: 12) {
        description.fixedSize(horizontal: false, vertical: true)
      }
      .font(.caption)
    }
    .frame(width: 300)
  }
}
