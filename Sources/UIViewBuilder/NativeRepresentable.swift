//
//  NativeRepresentable.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

public protocol NativeRepresentable: ComponentBase {
    associatedtype Native
    func create() -> Native
    func update(native: Native)
}

protocol _NativeRepresentable: _Component {
    associatedtype Native: NativeViewProtocol
    func create() -> Native
    func update(native: Native)
}

extension _NativeRepresentable {
    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        [create()]
    }

    @inline(__always)
    func _difference(with oldValue: Self?) -> [Difference] {
        if let oldValue = oldValue {
            if !self.isEqual(to: oldValue) {
                return [Difference(index: 0, change: .update(self))]
            }
            return [Difference(index: 0, change: .stable(self))]
        }
        return [Difference(index: 0, change: .insert(self))]
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        update(native: native as! Native)
    }

    @inline(__always)
    func _length() -> Int {
        1
    }
}

extension NativeRepresentable {
    @inline(__always)
    func traverse(oldValue: Self?) -> [Difference] {
        if let oldValue = oldValue {
            if !self.isEqual(to: oldValue) {
                return [Difference(index: 0, change: .update(self))]
            }
            return [Difference(index: 0, change: .stable(self))]
        }
        return [Difference(index: 0, change: .insert(self))]
    }
}

public protocol UIViewRepresentable: NativeRepresentable where Native: UIView {

}

public extension UIViewRepresentable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}

public extension UIViewRepresentable where Self: Equatable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}

public protocol UIViewControllerRepresentable: NativeRepresentable where Native: UIViewController {
}

extension UIViewControllerRepresentable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}


public extension UIViewControllerRepresentable where Self: Equatable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}
