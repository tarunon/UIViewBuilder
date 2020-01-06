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
        asAnyComponent()._create()
    }

    @inline(__always)
    func difference(with oldValue: Self?) -> [Difference] {
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

    @inline(__always)
    func isEqual(to other: Self?) -> Bool {
        asAnyComponent()._isEqual(to: other?.asAnyComponent())
    }
}

protocol _Component: ComponentBase {
    func _create() -> [NativeViewProtocol]
    func _difference(with oldValue: Self?) -> [Difference]
    func _update(native: NativeViewProtocol)
    func _length() -> Int
    func _isEqual(to other: Self?) -> Bool
}

extension _Component {
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}

extension _Component {
    @inline(__always)
    func _isEqual(to other: Self?) -> Bool {
        false
    }
}

extension _Component where Self: Equatable {
    @inline(__always)
    func _isEqual(to other: Self?) -> Bool {
        self == other
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
            traverse: { (oldValue) -> [Difference] in
                if !self.isEqual(to: oldValue) {
                    return self.body.difference(with: oldValue?.body)
                }
                return []
            },
            update: body.update(native:),
            length: body.length,
            isEqualTo: { _ in false },
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
