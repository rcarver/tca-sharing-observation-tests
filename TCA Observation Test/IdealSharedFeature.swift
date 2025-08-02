import Combine
import ComposableArchitecture
import Perception
import Sharing
import SwiftUI

//final class SharedState: SharedReaderKey, @unchecked Sendable {
//  typealias Value = ChildValue
//
//  @Shared var sharedValue: ChildValue
//  var currentValue: LockIsolated<ChildValue>
//
//  init(_ sharedValue: Shared<ChildValue>) {
//    self._sharedValue = sharedValue
//    self.currentValue = LockIsolated(sharedValue.wrappedValue)
//  }
//
//
//  var id: String { "foo" }
//  func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
//    continuation.resumeReturningInitialValue()
//  }
//  func subscribe(context: LoadContext<Value>, subscriber: SharedSubscriber<Value>) -> SharedSubscription {
//    let cancellable = $sharedValue.publisher.sink { [weak self] value in
//      guard let self else { return }
//      self.currentValue.setValue(value)
//    }
//    return SharedSubscription {
//      cancellable.cancel()
//    }
//  }
//}

@dynamicMemberLookup
@Perceptible
final class Reference<Value>: Equatable {
  init(_ value: Value, perceptionRegistrar: PerceptionRegistrar) {
    self.value = value
    self._$perceptionRegistrar = perceptionRegistrar
  }
  var value: Value
  @PerceptionIgnored
  var _$perceptionRegistrar: PerceptionRegistrar
  @PerceptionIgnored
  var accesses: Set<Access> = []
  struct Access: Hashable {
    let kp: PartialKeyPath<Value>
    let t: Any.Type
    let hash: AnyHashable
    func apply(_ value: inout Value, from: Value) {
      func open<T>(_ type: T.Type) -> WritableKeyPath<Value, T> {
        kp as! WritableKeyPath<Value, T>
      }
      let keyPath = _openExistential(t, do: open)
      value[keyPath: keyPath] = from[keyPath: keyPath]
    }
    static func == (lhs: Access, rhs: Access) -> Bool {
      lhs.hash == rhs.hash
    }
    func hash(into hasher: inout Hasher) {
      hasher.combine(hash)
    }
  }
  subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
    accesses.insert(
      Access(kp: keyPath, t: T.self, hash: keyPath)
    )
    _$perceptionRegistrar.access(self, keyPath: \.value)
    return value[keyPath: keyPath]
  }
  static func == (lhs: Reference<Value>, rhs: Reference<Value>) -> Bool {
    lhs === rhs
  }
}

@propertyWrapper
@Perceptible
final class SharedState<Value: Equatable> {
  @PerceptionIgnored
  var sharedValue: Shared<Value>
  @PerceptionIgnored
  var reference: Reference<Value>
  @PerceptionIgnored
  var cancellable: AnyCancellable?
  init(_ sharedValue: Shared<Value>) {
    self.sharedValue = Shared(projectedValue: sharedValue)
    self.reference = Reference(sharedValue.wrappedValue, perceptionRegistrar: _$perceptionRegistrar)
    self.cancellable = sharedValue.publisher.sink { [weak self] value in
      guard let self else { return }
      if value != self.reference.value {
        for a in self.reference.accesses {
          print("A", a)
          a.apply(&self.reference.value, from: value)
          //let x = value[keyPath: a]
        }
      }
    }
  }
  var projectedValue: SharedState {
    self
  }
  var wrappedValue: Reference<Value> {
    reference
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

extension SharedState: Equatable {
  static func == (lhs: SharedState, rhs: SharedState) -> Bool {
    lhs.sharedValue == rhs.sharedValue
  }
}

@Reducer
public struct IdealSharedRootFeature {
  @ObservableState
  public struct State: Equatable {
    @ObservationStateIgnored
    @SharedState var root: Reference<RootValue>
    var child1: IdealSharedChildFeature.State
    var child2: IdealSharedChildFeature.State
    init(root: Shared<RootValue> = Shared(value: .init())) {
      _root = SharedState(root)
      child1 = IdealSharedChildFeature.State(child: root.child1)
      child2 = IdealSharedChildFeature.State(child: root.child2)
    }
  }
  public enum Action: Sendable {
    case child1(IdealSharedChildFeature.Action)
    case child2(IdealSharedChildFeature.Action)
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
    @SharedState var child: Reference<ChildValue>
    init(child: Shared<ChildValue>) {
      _child = SharedState(child)
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
