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

extension ComponentSet.Empty: ComponentBase, NodeComponent {
    @inline(__always)
    func _difference(with oldValue: ComponentSet.Empty?) -> Differences {
        .empty
    }

    @inline(__always)
    func _destroy() -> Differences {
        .empty
    }
}

extension ComponentSet.Pair: ComponentBase, NodeComponent where C0: ComponentBase, C1: ComponentBase {
    @inline(__always)
    func _difference(with oldValue: ComponentSet.Pair<C0, C1>?) -> Differences {
        c0.difference(with: oldValue?.c0) + c1.difference(with: oldValue?.c1)
    }

    @inline(__always)
    func _destroy() -> Differences {
        c0.destroy() + c1.destroy()
    }
}

extension ComponentSet.Either: ComponentBase, NodeComponent where C0: ComponentBase, C1: ComponentBase {
    @inline(__always)
    func _difference(with oldValue: ComponentSet.Either<C0, C1>?) -> Differences {
        if C0.self is C1.Type && C1.self is C0.Type && !(C0.self is AnyComponent.Type) {
            return (c0?.difference(with: oldValue?.c0 ?? (oldValue?.c1 as? C0)) ??
                c1?.difference(with: oldValue?.c1 ?? (oldValue?.c0 as? C1)))!
        }
        var differences = Differences.empty
        switch (self, oldValue) {
        case (.c0(let c0), .c0(let oldValue)):
            differences = differences + c0.difference(with: oldValue)
        case (.c1(let c1), .c1(let oldValue)):
            differences = differences + c1.difference(with: oldValue)
        case (.c0(let c0), .c1(let oldValue)):
            differences = differences + oldValue.destroy()
            fallthrough
        case (.c0(let c0), .none):
            differences = differences + c0.difference(with: nil)
        case (.c1(let c1), .c0(let oldValue)):
            differences = differences + oldValue.destroy()
            fallthrough
        case (.c1(let c1), .none):
            differences = differences + c1.difference(with: nil)
        }
        return differences
    }

    func _destroy() -> Differences {
        switch self {
        case .c0(let c0): return c0.destroy()
        case .c1(let c1): return c1.destroy()
        }
    }
}
