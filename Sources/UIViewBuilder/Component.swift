//
//  Component.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

public protocol ComponentBase {
    func asAnyComponent() -> AnyComponent
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
