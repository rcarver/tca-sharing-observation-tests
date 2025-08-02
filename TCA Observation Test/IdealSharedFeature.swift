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

//@dynamicMemberLookup
@propertyWrapper
@Observable
final class SharedState<Value: Equatable> {
  @ObservationIgnored
  var sharedValue: Shared<Value>
  var wrappedValue: Value
  var accesses: [PartialKeyPath<Value>] = []
  var cancellable: AnyCancellable?
  init(_ sharedValue: Shared<Value>) {
    self.sharedValue = Shared(projectedValue: sharedValue)
    self.wrappedValue = sharedValue.wrappedValue
    self.cancellable = sharedValue.publisher.sink { [weak self] value in
      guard let self else { return }
      if value != self.wrappedValue {
        self.wrappedValue = value
      }
    }
  }
  var projectedValue: SharedState {
    self
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
  //  subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> T {
  //    accesses.append(keyPath)
  //    _$observationRegistrar.access(Self, keyPath: keyPath)
  //    return local[keyPath: keyPath]
  //  }
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
    @SharedState var root: RootValue
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
    @SharedState var child: ChildValue
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
