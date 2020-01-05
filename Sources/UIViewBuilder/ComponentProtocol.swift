//
//  ComponentProtocol.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

public protocol ComponentBase {
    func asAnyComponent() -> AnyComponent
}

struct Difference: Comparable {
    static func < (lhs: Difference, rhs: Difference) -> Bool {
        switch (lhs.change, rhs.change) {
        case (.remove, .remove): return lhs.index > rhs.index
        case (.remove, _): return true
        case (.insert, .remove): return false
        case (.insert, .insert): return lhs.index < rhs.index
        case (.insert, .update): return true
        case (.update, .update): return lhs.index < rhs.index
        case (.update, _): return false
        }
    }

    static func == (lhs: Difference, rhs: Difference) -> Bool {
        switch (lhs.change, rhs.change) {
        case (.insert, .insert): return lhs.index == rhs.index
        case (.remove, .remove): return lhs.index == rhs.index
        case (.update, .update): return lhs.index == rhs.index
        default: return false
        }
    }

    enum Change {
        case insert(ComponentBase)
        case update(ComponentBase)
        case remove(ComponentBase)
    }
    var index: Int
    var change: Change

    func with(offset: Int, oldOffset: Int) -> Difference {
        var index = self.index
        switch self.change {
        case .remove:
            index += oldOffset
        case .insert, .update:
            index += offset
        }
        return Difference(index: index, change: change)
    }
}

extension Collection where Element == Difference {
    func staged() -> (removals: [Difference], insertions: [Difference], updations: [Difference]) {
        return reduce(into: (removals: [Difference](), insertions: [Difference](), updations: [Difference]())) { (result, difference) in
            switch difference.change {
            case .insert:
                result.insertions.append(difference)
            case .update:
                result.updations.append(difference)
            case .remove:
                result.removals.append(difference)
            }
        }
    }
}

extension ComponentBase {
    @inline(__always)
    func create() -> [NativeViewProtocol] {
        asAnyComponent().create()
    }

    @inline(__always)
    func difference(with oldValue: Self?) -> [Difference] {
        asAnyComponent().difference(with: oldValue?.asAnyComponent())
    }

    @inline(__always)
    func update(native: NativeViewProtocol) {
        asAnyComponent().update(native: native)
    }

    @inline(__always)
    func length() -> Int {
        asAnyComponent().length()
    }
}

protocol _Component: ComponentBase {
    func create() -> [NativeViewProtocol]
    func difference(with oldValue: Self?) -> [Difference]
    func update(native: NativeViewProtocol)
    func length() -> Int
}

extension _Component {
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}

public protocol Component: ComponentBase, Equatable {
    associatedtype Body: ComponentBase
    var body: Body { get }
}

extension Component {
    public func asAnyComponent() -> AnyComponent {
        let erased = body.asAnyComponent()
        return AnyComponent(
            create: erased.create,
            traverse: { (oldValue) -> [Difference] in
                if self != oldValue {
                    return erased.difference(with: oldValue?.body.asAnyComponent())
                }
                return []
            },
            update: erased.update,
            length: erased.length,
            body: self
        )
    }
}

extension ComponentBase {
    static var reuseIdentifier: String {
        return String(describing: ObjectIdentifier(self))
    }

    var reuseIdentifier: String {
        return Self.reuseIdentifier
    }
}
