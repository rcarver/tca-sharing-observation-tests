import ComposableArchitecture
import Perception
import SwiftUI

/// This version implements a purely state-based UI which shows minimal observation.
@Reducer
public struct RootFeature {
  @ObservableState
  public struct State: Equatable {
    var root: RootValue
    var child1: ChildFeature.State
    var child2: ChildFeature.State
    init(root: RootValue = .init()) {
      self.root = root
      child1 = ChildFeature.State(child: root.child1)
      child2 = ChildFeature.State(child: root.child2)
    }
  }
  public enum Action: Sendable {
    case child1(ChildFeature.Action)
    case child2(ChildFeature.Action)
    case incrementButtonTapped
  }
  public var body: some ReducerOf<Self> {
    Scope(state: \.child1, action: \.child1) {
      ChildFeature()
    }
    Scope(state: \.child2, action: \.child2) {
      ChildFeature()
    }
    Reduce { state, action in
      switch action {
      case .child1, .child2:
        return .none
      case .incrementButtonTapped:
        state.root.count += 1
        return .none
      }
    }
  }
}

@Reducer
public struct ChildFeature {
  @ObservableState
  public struct State: Equatable {
    var child: ChildValue
    init(
      child: ChildValue
    ) {
      self.child = child
    }
  }
  public enum Action: Sendable, BindableAction {
    case binding(BindingAction<State>)
    case noopButtonTapped
  }
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .noopButtonTapped:
        state.child.toggle1 = state.child.toggle1
        return .none
      }
    }
  }
}

struct RootView: View {
  @Bindable var store: StoreOf<RootFeature>
  var body: some View {
    let _ = RootView._printChanges()
    VStack {
      Text(store.root.count.formatted())
      Button("Increment") {
        store.send(.incrementButtonTapped)
      }
      HStack {
        VStack {
          Text("Child 1")
          ChildView(store: store.scope(state: \.child1, action: \.child1))
        }
        VStack {
          Text("Child 2")
          ChildView(store: store.scope(state: \.child2, action: \.child2))
        }
      }
      .padding()
    }
    .padding()
    .background(Color.random)
  }
}

struct ChildView: View {
  @Bindable var store: StoreOf<ChildFeature>
  var body: some View {
    let _ = ChildView._printChanges()
    VStack {
      Button {
        store.send(.noopButtonTapped)
      } label: {
        Text("Noop")
      }
      ToggleView(name: "root 1", isOn: $store.child.toggle1)
      ToggleView(name: "root 2", isOn: $store.child.toggle2)
    }
    .padding()
    .background(Color.random)
  }
}

#Preview {
  let store = Store(
    initialState: RootFeature.State()
  ) {
    RootFeature()
  }
  RootView(store: store)
}
