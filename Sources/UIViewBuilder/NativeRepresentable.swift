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

extension NativeRepresentable {
    func traverse(oldValue: Self?) -> [Difference] {
        if let oldValue = oldValue {
            if !self.isEqual(to: oldValue) {
                return [Difference(index: 0, change: .update(self))]
            }
            return []
        }
        return [Difference(index: 0, change: .insert(self))]
    }
}

public protocol UIViewRepresentable: NativeRepresentable where Native: UIView {

}

public extension UIViewRepresentable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}

public extension UIViewRepresentable where Self: Equatable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}

public protocol UIViewControllerRepresentable: NativeRepresentable where Native: UIViewController {
}

extension UIViewControllerRepresentable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}


public extension UIViewControllerRepresentable where Self: Equatable {
    @inline(__always)
    func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}
