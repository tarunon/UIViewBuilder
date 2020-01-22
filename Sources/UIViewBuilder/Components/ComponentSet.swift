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
    public typealias Properties = ComponentSet.Empty

    @inline(__always)
    func _difference(with oldValue: ComponentSet.Empty?) -> Differences {
        .empty
    }

    @inline(__always)
    func _destroy() -> Differences {
        .empty
    }

    public var properties: ComponentSet.Empty {
        get { self }
        set { self = newValue }
    }
}

extension ComponentSet.Pair: NodeComponent, ComponentBase, _Component where C0: ComponentBase, C1: ComponentBase {
    @inline(__always)
    func _difference(with oldValue: ComponentSet.Pair<C0, C1>?) -> Differences {
        c0.difference(with: oldValue?.c0) + c1.difference(with: oldValue?.c1)
    }

    @inline(__always)
    func _destroy() -> Differences {
        c0.destroy() + c1.destroy()
    }

    public typealias Properties = ComponentSet.Pair<C0.Properties, C1.Properties>

    @inline(__always)
    public var properties: Properties {
        _read {
            yield .init(c0: c0.properties, c1: c1.properties)
        }
        _modify {
            var tmp = Properties(c0: c0.properties, c1: c1.properties)
            yield &tmp
            c0.properties = tmp.c0
            c1.properties = tmp.c1
        }
    }
}

extension ComponentSet.Either: NodeComponent, ComponentBase, _Component where  C0: ComponentBase, C1: ComponentBase {
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

    @inline(__always)
    func _destroy() -> Differences {
        switch self {
        case .c0(let c0): return c0.destroy()
        case .c1(let c1): return c1.destroy()
        }
    }

    public typealias Properties = ComponentSet.Either<C0.Properties, C1.Properties>

    @inline(__always)
    public var properties: ComponentSet.Either<C0.Properties, C1.Properties> {
        _read {
            switch self {
            case .c0(let c0):
                yield .c0(c0.properties)
            case .c1(let c1):
                yield .c1(c1.properties)
            }
        }
        _modify {
            switch self {
            case .c0(var c0):
                var tmp = Properties.c0(c0.properties)
                yield &tmp
                c0.properties = tmp.c0!
                self = .c0(c0)
            case .c1(var c1):
                var tmp = Properties.c1(c1.properties)
                yield &tmp
                c1.properties = tmp.c1!
                self = .c1(c1)
            }

        }

    }
}
