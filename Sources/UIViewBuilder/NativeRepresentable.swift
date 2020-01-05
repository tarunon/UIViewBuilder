//
//  NativeRepresentable.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

public protocol NativeRepresentable: ComponentBase, Equatable {
    associatedtype Native
    func create() -> Native
    func update(native: Native)
}

extension NativeRepresentable {
    func traverse(oldValue: Self?) -> [Difference] {
        if let oldValue = oldValue {
            if self != oldValue {
                return [Difference(index: 0, change: .update(self))]
            }
            return []
        }
        return [Difference(index: 0, change: .insert(self))]
    }
}

extension NativeRepresentable where Native: UIView {
    @inline(__always)
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}

extension NativeRepresentable where Native: UIViewController {
    @inline(__always)
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(body: self)
    }
}
