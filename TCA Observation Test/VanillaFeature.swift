import Perception
import SwiftUI

@Perceptible
final class RootModel {
  var count: Int = 0
  var child1 = ChildModel()
  var child2 = ChildModel()
}

@Perceptible
final class ChildModel {
  var toggle1 = false
  var toggle2 = false
}

extension RootModel {
  func incrementButtonTapped() {
    count += 1
  }
}

extension ChildModel {
  func noopButtonTapped() {
    self.toggle1 = self.toggle1
  }
}

struct VanillaRootView: View {
  @Bindable var model: RootModel
  var body: some View {
    let _ = VanillaRootView._printChanges()
    VStack {
      Text(model.count.formatted())
      Button("Increment") {
        model.incrementButtonTapped()
      }
      HStack {
        VStack {
          Text("Child 1")
          VanillaChildView(model: model.child1)
        }
        VStack {
          Text("Child 2")
          VanillaChildView(model: model.child2)
        }
      }
      .padding()
    }
    .padding()
    .background(Color.random)
  }
}

struct VanillaChildView: View {
  @Bindable var model: ChildModel
  var body: some View {
    let _ = VanillaChildView._printChanges()
    VStack {
      Button {
        model.noopButtonTapped()
      } label: {
        Text("Noop")
      }
      ToggleView(name: "root 1", isOn: $model.toggle1)
      ToggleView(name: "root 2", isOn: $model.toggle2)
    }
    .padding()
    .background(Color.random)
  }
  struct TogglesView: View {
    @Bindable var model: ChildModel
    var body: some View {
      ToggleView(name: "root 1", isOn: $model.toggle1)
      ToggleView(name: "root 2", isOn: $model.toggle2)
    }
  }
}

#Preview {
  let model = RootModel()
  VanillaRootView(model: model)
}
