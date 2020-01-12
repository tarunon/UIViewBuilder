//
//  Component.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

public protocol ComponentBase: MaybeEquatable {
    func asAnyComponent() -> AnyComponent
}

extension ComponentBase {
    @inline(__always)
    func create() -> [NativeViewProtocol] {
        asAnyComponent()._create()
    }

    @inline(__always)
    func difference(with oldValue: Self?) -> Differences {
        asAnyComponent()._difference(with: oldValue?.asAnyComponent())
    }

    @inline(__always)
    func update(native: NativeViewProtocol) {
        asAnyComponent()._update(native: native)
    }

    @inline(__always)
    func length() -> Int {
        asAnyComponent()._length()
    }
}

protocol _Component: ComponentBase {
    func _create() -> [NativeViewProtocol]
    func _difference(with oldValue: Self?) -> Differences
    func _update(native: NativeViewProtocol)
    func _length() -> Int
}

extension _Component {
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}

public protocol Component: ComponentBase {
    associatedtype Body: ComponentBase
    var body: Body { get }
}

extension Component {
    public func asAnyComponent() -> AnyComponent {
        return AnyComponent(
            create: body.create,
            difference: { (oldValue) in
                if !self.isEqual(to: oldValue) {
                    return self.body.difference(with: oldValue?.body)
                }
                return .empty
            },
            update: body.update(native:),
            length: body.length,
            content: self
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
