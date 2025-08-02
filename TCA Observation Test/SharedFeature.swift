import ComposableArchitecture
import Perception
import SwiftUI

@Reducer
public struct SharedRootFeature {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @Shared var root: RootValue
    var child1: SharedChildFeature.State
    var child2: SharedChildFeature.State
    init(root: Shared<RootValue> = Shared(value: .init())) {
      _root = root
      child1 = SharedChildFeature.State(child: _root.child1)
      child2 = SharedChildFeature.State(child: _root.child2)
    }
  }
  public enum Action: Sendable {
    case child1(SharedChildFeature.Action)
    case child2(SharedChildFeature.Action)
    case incrementButtonTapped
  }
  public var body: some ReducerOf<Self> {
    Scope(state: \.child1, action: \.child1) {
      SharedChildFeature()
    }
    Scope(state: \.child2, action: \.child2) {
      SharedChildFeature()
    }
    Reduce { state, action in
      switch action {
      case .child1, .child2:
        return .none
      case .incrementButtonTapped:
        state.$root.withLock { $0.count += 1 }
        return .none
      }
    }
  }
}

@Reducer
public struct SharedChildFeature {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @Shared var child: ChildValue
    init(
      child: Shared<ChildValue>
    ) {
      _child = child
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
        state.$child.withLock { $0.toggle1 = state.child.toggle1 }
        return .none
      }
    }
  }
}

struct SharedRootView: View {
  @Bindable var store: StoreOf<SharedRootFeature>
  var body: some View {
    let _ = SharedRootView._printChanges()
    VStack {
      Text(store.root.count.formatted())
      Button("Increment") {
        store.send(.incrementButtonTapped)
      }
      HStack {
        VStack {
          Text("Child 1")
          SharedChildView(store: store.scope(state: \.child1, action: \.child1))
        }
        VStack {
          Text("Child 2")
          SharedChildView(store: store.scope(state: \.child2, action: \.child2))
        }
      }
      .padding()
    }
    .padding()
    .background(Color.random)
  }
}

struct SharedChildView: View {
  @Bindable var store: StoreOf<SharedChildFeature>
  var body: some View {
    let _ = SharedChildView._printChanges()
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
    initialState: SharedRootFeature.State()
  ) {
    SharedRootFeature()
  }
  SharedRootView(store: store)
}
