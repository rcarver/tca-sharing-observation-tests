import SwiftUI
import ComposableArchitecture

@ObservableState
struct RootValue: Equatable {
  var count = 0
  var child1 = ChildValue()
  var child2 = ChildValue()
}

@ObservableState
struct ChildValue: Equatable {
  var toggle1 = false
  var toggle2 = false
}

struct ToggleView: View {
  var name: String
  @Binding var isOn: Bool
  var body: some View {
    let _ = print("evaluated ToggleView \(name)")
    Toggle("isOn", isOn: $isOn)
      .padding()
      .background(Color.random)
  }
}

extension Color {
  static var random: Self {
    .init(
      red: .random(in: 0...0.5),
      green: .random(in: 0...0.5),
      blue: .random(in: 0...0.5)
    )
  }
}
