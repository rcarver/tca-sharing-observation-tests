import Combine
import ComposableArchitecture
import Perception
import Sharing
import SwiftUI

/// This version attempts to match the efficiency of StateFeature by extending
/// Sharing to use ObservableState
@Reducer
public struct ObservableSharedRootFeature {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @Shared var root: ObservableRootValue
    var child1: ObservableSharedChildFeature.State
    var child2: ObservableSharedChildFeature.State
    init(root: Shared<ObservableRootValue> = Shared(value: .init())) {
      _root = root
      child1 = ObservableSharedChildFeature.State(child: root.child1)
      child2 = ObservableSharedChildFeature.State(child: root.child2)
    }
  }
  public enum Action: Sendable {
    case child1(ObservableSharedChildFeature.Action)
    case child2(ObservableSharedChildFeature.Action)
    case child1ToggleButtonTapped
    case incrementButtonTapped
  }
  public var body: some ReducerOf<Self> {
    Scope(state: \.child1, action: \.child1) {
      ObservableSharedChildFeature()
    }
    Scope(state: \.child2, action: \.child2) {
      ObservableSharedChildFeature()
    }
    Reduce { state, action in
      switch action {
      case .child1, .child2:
        return .none
      case .child1ToggleButtonTapped:
        state.$root.withLock { $0.child1.toggle1.toggle() }
        return .none
      case .incrementButtonTapped:
        state.$root.withLock { $0.count += 1 }
        return .none
      }
    }
  }
}

@Reducer
public struct ObservableSharedChildFeature {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @Shared var child: ObservableChildValue
    init(child: Shared<ObservableChildValue>) {
      _child = child
    }
  }
  public enum Action: Sendable, BindableAction {
    case binding(BindingAction<State>)
    case noopButtonTapped
    case toggle1(Bool)
    case toggle2(Bool)
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
      case let .toggle1(bool):
        state.$child.withLock { $0.toggle1 = bool }
        return .none
      case let .toggle2(bool):
        state.$child.withLock { $0.toggle2 = bool }
        return .none
      }
    }
  }
}

struct ObservableSharedRootView: View {
  @Bindable var store: StoreOf<ObservableSharedRootFeature>
  var body: some View {
    let _ = ObservableSharedRootView._printChanges()
    VStack {
      Text(store.root.count.formatted())
      Button("Increment") {
        store.send(.incrementButtonTapped)
      }
      Button("Toggle child 1 toggle 1") {
        store.send(.child1ToggleButtonTapped)
      }
      HStack {
        VStack {
          Text("Child 1")
          ObservableSharedChildView(store: store.scope(state: \.child1, action: \.child1))
        }
        VStack {
          Text("Child 2")
          ObservableSharedChildView(store: store.scope(state: \.child2, action: \.child2))
        }
      }
      .padding()
    }
    .padding()
    .background(Color.random)
  }
}

struct ObservableSharedChildView: View {
  @Bindable var store: StoreOf<ObservableSharedChildFeature>
  var body: some View {
    let _ = ObservableSharedChildView._printChanges()
    VStack {
      Button {
        store.send(.noopButtonTapped)
      } label: {
        Text("Noop")
      }
      ToggleView(name: "root 1", isOn: $store.child.toggle1.sending(\.toggle1))
      ToggleView(name: "root 2", isOn: $store.child.toggle2.sending(\.toggle2))
    }
    .padding()
    .background(Color.random)
  }
}

#Preview {
  let store = Store(
    initialState: ObservableSharedRootFeature.State()
  ) {
    ObservableSharedRootFeature()
  }
  ObservableSharedRootView(store: store)
}
