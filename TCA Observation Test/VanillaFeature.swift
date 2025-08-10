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
  func child1ToggleButtonTapped() {
    child1.toggle1.toggle()
  }
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
      Button("Toggle child 1 toggle 1") {
        model.child1ToggleButtonTapped()
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
    let _ = Self._printChanges()
    VStack {
      Button {
        model.noopButtonTapped()
      } label: {
        Text("Noop")
      }
      ToggleView(name: "child 1", isOn: $model.toggle1)
      ToggleView(name: "child 2", isOn: $model.toggle2)
    }
    .padding()
    .background(Color.random)
  }
}

#Preview {
  let model = RootModel()
  VanillaRootView(model: model)
}
