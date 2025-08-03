import Combine
import ComposableArchitecture
import Perception
import Sharing
import SwiftUI

@dynamicMemberLookup
@Perceptible
public final class Observed<Value: Equatable>: Equatable {
  var value: Value
  @PerceptionIgnored var accesses: Set<Access> = []
  public init(_ value: Shared<Value>) {
    self.value = value.wrappedValue
  }
  struct Access: Hashable {
    let kp: PartialKeyPath<Value>
    let t: Any.Type
    let hash: AnyHashable
    func isEqual(_ lhs: Value, _ rhs: Value) -> Bool {
      func open<T>(_ type: T.Type) -> KeyPath<Value, T> {
        kp as! KeyPath<Value, T>
      }
      let keyPath = _openExistential(t, do: open)
      return _isEqual(lhs[keyPath: keyPath], rhs[keyPath: keyPath]) ?? false
    }
    static func == (lhs: Access, rhs: Access) -> Bool {
      lhs.hash == rhs.hash
    }
    func hash(into hasher: inout Hasher) {
      hasher.combine(hash)
    }
  }
  func updateIfNeeded(_ newValue: Value) {
    // Check if any accessed fields have changed. If so, update the entire value.
    if accesses.contains(where: { !$0.isEqual(value, newValue) }) {
      value = newValue
    }
  }
  public var wrappedValue: Value {
    value
  }
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    // Track each field access.
    accesses.insert(Access(kp: keyPath, t: T.self, hash: keyPath))
    return value[keyPath: keyPath]
  }
  public static func == (lhs: Observed<Value>, rhs: Observed<Value>) -> Bool {
    lhs.value == rhs.value
  }
}

fileprivate func _isEqual(_ lhs: Any, _ rhs: Any) -> Bool? {
  (lhs as? any Equatable)?.isEqual(other: rhs)
}

extension Equatable {
  fileprivate func isEqual(other: Any) -> Bool {
    self == other as? Self
  }
}

/// A simple wrapper over Shared that causes all access to go through `Observed`. When
/// the shared value updates, it efficiently that value to only modify accessed fields.
@propertyWrapper
@Perceptible
public final class ObservedShared<Value: Equatable> {
  @PerceptionIgnored var sharedValue: Shared<Value>
  @PerceptionIgnored var sharedView: Observed<Value>
  @PerceptionIgnored var cancellable: AnyCancellable?
  public init(_ sharedValue: Shared<Value>) {
    self.sharedValue = Shared(projectedValue: sharedValue)
    self.sharedView = Observed(sharedValue)
    self.cancellable = sharedValue.publisher.sink { [weak self] value in
      guard let self else { return }
      self.sharedView.updateIfNeeded(value)
    }
  }
  public var projectedValue: ObservedShared {
    self
  }
  public var wrappedValue: Observed<Value> {
    sharedView
  }
  public func withLock<R>(
    _ operation: (inout Value) throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) rethrows -> R {
    try sharedValue.withLock(operation)
  }
}

extension ObservedShared: Equatable {
  public static func == (lhs: ObservedShared, rhs: ObservedShared) -> Bool {
    lhs.sharedValue == rhs.sharedValue
  }
}
ç
/// This version attempts to match the efficiency of StateFeature by using
/// experimental tools over Shared to reduce over-observation.
@Reducer
public struct IdealSharedRootFeature {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @ObservedShared var root: Observed<RootValue>
    var child1: IdealSharedChildFeature.State
    var child2: IdealSharedChildFeature.State
    init(root: Shared<RootValue> = Shared(value: .init())) {
      _root = ObservedShared(root)
      child1 = IdealSharedChildFeature.State(child: root.child1)
      child2 = IdealSharedChildFeature.State(child: root.child2)
    }
  }
  public enum Action: Sendable {
    case child1(IdealSharedChildFeature.Action)
    case child2(IdealSharedChildFeature.Action)
    case child1ToggleButtonTapped
    case incrementButtonTapped
  }
  public var body: some ReducerOf<Self> {
    Scope(state: \.child1, action: \.child1) {
      IdealSharedChildFeature()
    }
    Scope(state: \.child2, action: \.child2) {
      IdealSharedChildFeature()
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
public struct IdealSharedChildFeature {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @ObservedShared var child: Observed<ChildValue>
    init(child: Shared<ChildValue>) {
      _child = ObservedShared(child)
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

struct IdealSharedRootView: View {
  @Bindable var store: StoreOf<IdealSharedRootFeature>
  var body: some View {
    let _ = IdealSharedRootView._printChanges()
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
          IdealSharedChildView(store: store.scope(state: \.child1, action: \.child1))
        }
        VStack {
          Text("Child 2")
          IdealSharedChildView(store: store.scope(state: \.child2, action: \.child2))
        }
      }
      .padding()
    }
    .padding()
    .background(Color.random)
  }
}

struct IdealSharedChildView: View {
  @Bindable var store: StoreOf<IdealSharedChildFeature>
  var body: some View {
    let _ = IdealSharedChildView._printChanges()
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
    initialState: IdealSharedRootFeature.State()
  ) {
    IdealSharedRootFeature()
  }
  IdealSharedRootView(store: store)
}
