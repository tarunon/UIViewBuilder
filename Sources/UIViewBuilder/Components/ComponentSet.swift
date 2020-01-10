//
//  TableViewCellComposers.swift
//  
//
//  Created by tarunon on 2019/12/03.
//
import UIKit

public enum ComponentSet {
    public struct Empty {}

    public struct Pair<C0, C1> {
        var c0: C0
        var c1: C1
    }

    public enum Either<C0, C1> {
        case c0(C0)
        case c1(C1)

        var c0: C0? {
            switch self {
            case .c0(let c0): return c0
            default: return nil
            }
        }

        var c1: C1? {
            switch self {
            case .c1(let c1): return c1
            default: return nil
            }
        }
    }
}

extension ComponentSet.Empty: Equatable {}
extension ComponentSet.Pair: Equatable where C0: Equatable, C1: Equatable {}
extension ComponentSet.Pair: MaybeEquatable where C0: MaybeEquatable, C1: MaybeEquatable {}
extension ComponentSet.Either: Equatable where C0: Equatable, C1: Equatable {}
extension ComponentSet.Either: MaybeEquatable where C0: MaybeEquatable, C1: MaybeEquatable {}

extension ComponentSet.Either where C1 == ComponentSet.Empty {
    init(from optional: C0?) {
        if let value = optional {
            self = .c0(value)
        } else {
            self = .c1(.init())
        }
    }
}

extension ComponentSet.Empty: ComponentBase, _Component {
    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        []
    }

    @inline(__always)
    func _difference(with oldValue: ComponentSet.Empty?) -> [Difference] {
        []
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {

    }

    @inline(__always)
    func _length() -> Int {
        0
    }
}

extension ComponentSet.Pair: ComponentBase, _Component where C0: ComponentBase, C1: ComponentBase {
    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        c0.create() + c1.create()
    }

    @inline(__always)
    func _difference(with oldValue: ComponentSet.Pair<C0, C1>?) -> [Difference] {
        c0.difference(with: oldValue?.c0) +
            c1.difference(with: oldValue?.c1).map { $0.with(offset: c0.length(), oldOffset: oldValue?.c0.length() ?? 0) }
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        fatalError()
    }

    @inline(__always)
    func _length() -> Int {
        c0.length() + c1.length()
    }
}

extension ComponentSet.Either: ComponentBase, _Component where C0: ComponentBase, C1: ComponentBase {
    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        c0?.create() ?? c1?.create() ?? []
    }

    @inline(__always)
    func _difference(with oldValue: ComponentSet.Either<C0, C1>?) -> [Difference] {
        if C0.self is C1.Type && C1.self is C0.Type && !(C0.self is AnyComponent.Type) {
            return c0?.difference(with: oldValue?.c0 ?? (oldValue?.c1 as? C0)) ??
                c1?.difference(with: oldValue?.c1 ?? (oldValue?.c0 as? C1)) ?? []
        }
        var result = [Difference]()
        switch (self, oldValue) {
        case (.c0(let c0), .c0(let oldValue)):
            result += c0.difference(with: oldValue)
        case (.c1(let c1), .c1(let oldValue)):
            result += c1.difference(with: oldValue)
        case (.c0(let c0), .c1(let oldValue)):
            result += (0..<oldValue.length()).reversed().map { Difference(index: $0, change: .remove(oldValue)) }
            fallthrough
        case (.c0(let c0), .none):
            result += c0.difference(with: nil)
        case (.c1(let c1), .c0(let oldValue)):
            result += (0..<oldValue.length()).reversed().map { Difference(index: $0, change: .remove(oldValue)) }
            fallthrough
        case (.c1(let c1), .none):
            result += c1.difference(with: nil)
        }
        return result
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        fatalError()
    }

    @inline(__always)
    func _length() -> Int {
        switch self {
        case .c0(let c0): return c0.length()
        case .c1(let c1): return c1.length()
        }
    }
}
