//
//  Representable.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

public protocol RepresentableBase: ComponentBase {
    func _create() -> Any
    func _update(native: Any)
}

extension RepresentableBase {
    func create() -> NativeViewProtocol {
        _create() as! NativeViewProtocol
    }

    func update(native: NativeViewProtocol) {
        _update(native: native)
    }
}

public extension RepresentableBase {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}

protocol NativeRepresentable: RepresentableBase {
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


public protocol UIViewRepresentable: RepresentableBase {
    associatedtype Native: UIView
    func create() -> Native
    func update(native: Native)
}

public extension UIViewRepresentable {
    @inline(__always)
    func _create() -> Any {
        create() as Native
    }

    @inline(__always)
    func _update(native: Any) {
        update(native: native as! Native)
    }
}

public protocol UIViewControllerRepresentable: RepresentableBase {
    associatedtype Native: UIViewController
    func create() -> Native
    func update(native: Native)
}

extension UIViewControllerRepresentable {
    @inline(__always)
    func _create() -> Any {
        create() as Native
    }

    @inline(__always)
    func _update(native: Any) {
        update(native: native as! Native)
    }
}
