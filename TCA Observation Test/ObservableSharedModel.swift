import Sharing
import Observation

@ObservableValue
struct ObservableRootValue: Equatable, Sendable {
  var count = 0
  var child1 = ObservableChildValue()
  var child2 = ObservableChildValue()
}

@ObservableValue
struct ObservableChildValue: Equatable, Sendable {
  var toggle1 = false
  var toggle2 = false
}
