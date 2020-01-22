//
//  DynamicProperty.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/20.
//

public protocol DynamicProperty {
    mutating func update()
    func handleUpdate(_ f: @escaping () -> ())
}

public protocol DynamicProperties: DynamicProperty {
    associatedtype Body: DynamicProperty
    var body: Body { get set }
}

public extension DynamicProperties {
    mutating func update() {
        body.update()
    }
}

extension ComponentSet.Empty: DynamicProperty {
    public mutating func update() {}
    public func handleUpdate(_ f: @escaping () -> ()) {

    }
}

extension ComponentSet.Pair: DynamicProperty where C0: DynamicProperty, C1: DynamicProperty {
    public mutating func update() {
        c0.update()
        c1.update()
    }

    public func handleUpdate(_ f: @escaping () -> ()) {
        c0.handleUpdate(f)
        c1.handleUpdate(f)
    }
}

extension ComponentSet.Either: DynamicProperty where C0: DynamicProperty, C1: DynamicProperty {
    public mutating func update() {
        switch self {
        case .c0(var c0):
            c0.update()
            self = .c0(c0)
        case .c1(var c1):
            c1.update()
            self = .c1(c1)
        }
    }

    public func handleUpdate(_ f: @escaping () -> ()) {
        switch self {
        case .c0(let c0):
            c0.handleUpdate(f)
        case .c1(let c1):
            c1.handleUpdate(f)
        }
    }
}

extension Dictionary: DynamicProperty where Value: DynamicProperty {
    public mutating func update() {
        self = mapValues { var x = $0; x.update(); return x }
    }

    public func handleUpdate(_ f: @escaping () -> ()) {
        forEach { $0.value.handleUpdate(f) }
    }
}

public struct AnyDynamicProperty: DynamicProperty {
    var body: DynamicProperty

    init<D: DynamicProperty>(@ComponentBuilder _ creation: () -> D) {
        body = creation()
    }

    public mutating func update() {
        body.update()
    }

    public func handleUpdate(_ f: @escaping () -> ()) {
        body.handleUpdate(f)
    }
}
