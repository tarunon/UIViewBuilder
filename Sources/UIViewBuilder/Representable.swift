//
//  Representable.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

public protocol RepresentableBase: _Component {
    func _create() -> Any
    func _update(native: Any)
}

extension RepresentableBase {
    @inline(__always)
    func create() -> NativeViewProtocol {
        _create() as! NativeViewProtocol
    }

    @inline(__always)
    func update(native: NativeViewProtocol) {
        _update(native: native)
    }

    @inline(__always)
    func difference(with oldValue: Self?) -> Differences {
        asAnyComponent()._difference(with: oldValue?.asAnyComponent())
    }

    @inline(__always)
    func destroy() -> Differences {
        asAnyComponent()._destroy()
    }

    @inline(__always)
    static var reuseIdentifier: String {
        return String(describing: ObjectIdentifier(self))
    }

    @inline(__always)
    var reuseIdentifier: String {
        return Self.reuseIdentifier
    }

    @inline(__always)
    public var properties: ComponentSet.Empty {
        get { .init() }
        set {}
    }
}


public extension RepresentableBase where Self: ComponentBase {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}

protocol NativeRepresentable: RepresentableBase, ComponentBase {
    associatedtype Native: NativeViewProtocol
    func create() -> Native
    func update(native: Native)
}

extension NativeRepresentable {
    @inline(__always)
    public func _create() -> Any {
        create() as Native
    }

    @inline(__always)
    public func _update(native: Any) {
        update(native: native as! Native)
    }
}


public protocol UIViewRepresentable: RepresentableBase, ComponentBase {
    associatedtype View: UIView
    func create() -> View
    func update(native: View)
}

public extension UIViewRepresentable {
    internal typealias Native = NativeViewWrapper<View, Self>

    @inline(__always)
    func _create() -> Any {
        Native(view: create(), content: self)
    }

    @inline(__always)
    func _update(native: Any) {
        update(native: (native as! Native).view)
    }
}

public protocol UIViewControllerRepresentable: RepresentableBase, ComponentBase {
    associatedtype ViewController: UIViewController
    func create() -> ViewController
    func update(native: ViewController)
}

extension UIViewControllerRepresentable {
    internal typealias Native = NativeViewControllerWrapper<ViewController, Self>

    @inline(__always)
    func _create() -> Any {
        Native(viewController: create(), content: self)
    }

    @inline(__always)
    func _update(native: Any) {
        update(native: (native as! Native).viewController)
    }
}
