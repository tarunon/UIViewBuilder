//
//  ComponentProtocol.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

typealias Mount = (Mountable, UIViewController) -> ()

public protocol ComponentBase {
    func asAnyComponent() -> AnyComponent
}

struct Change {
    enum Difference {
        case insert(ComponentBase)
        case update(ComponentBase)
        case remove
    }
    var index: Int
    var difference: Difference

    func with(offset: Int) -> Change {
        Change(index: index + offset, difference: difference)
    }
}

extension ComponentBase {
    @inline(__always)
    func create() -> [NativeViewProtocol] {
        asAnyComponent().create()
    }

    @inline(__always)
    func traverse(oldValue: Self?) -> [Change] {
        asAnyComponent().traverse(oldValue: oldValue?.asAnyComponent())
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
    func traverse(oldValue: Self?) -> [Change]
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
            traverse: { (oldValue) -> [Change] in
                if self != oldValue {
                    return erased.traverse(oldValue: oldValue?.body.asAnyComponent())
                }
                return []
            },
            update: erased.update,
            length: erased.length,
            body: self
        )
    }
}
