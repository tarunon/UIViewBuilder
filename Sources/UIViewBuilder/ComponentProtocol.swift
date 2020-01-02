//
//  ComponentProtocol.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

typealias Mount = (UIStackView, UIViewController) -> ()

public protocol ComponentBase {
    func asAnyComponent() -> AnyComponent
}

extension ComponentBase {
    @inline(__always)
    func create(prev: NativeViewProtocol?) -> NativeViewProtocol {
        asAnyComponent().create(prev: prev)
    }

    @inline(__always)
    func update(native: NativeViewProtocol, oldValue: Self?) -> [Mount] {
        asAnyComponent().update(native: native as! AnyNativeView, oldValue: oldValue?.asAnyComponent())
    }
}

protocol _Component: ComponentBase {
    associatedtype NativeView: NativeViewProtocol

    func create(prev: NativeViewProtocol?) -> NativeView
    func update(native: NativeView, oldValue: Self?) -> [Mount]
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
            update: { (native, oldValue) -> [Mount] in
                if self != oldValue {
                    return erased.update(native: native, oldValue: oldValue?.body.asAnyComponent())
                }
                return []
            },
            body: self
        )
    }
}
