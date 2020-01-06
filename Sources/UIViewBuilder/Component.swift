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

    @inline(__always)
    func isEqual(to other: Self?) -> Bool {
        asAnyComponent().isEqual(to: other?.asAnyComponent())
    }
}

protocol _Component: ComponentBase {
    func create() -> [NativeViewProtocol]
    func difference(with oldValue: Self?) -> [Difference]
    func update(native: NativeViewProtocol)
    func length() -> Int
    func isEqual(to other: Self?) -> Bool
}

extension _Component {
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}

extension _Component {
    @inline(__always)
    func isEqual(to other: Self?) -> Bool {
        false
    }
}

extension _Component where Self: Equatable {
    @inline(__always)
    func isEqual(to other: Self?) -> Bool {
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
