//
//  Representable.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

public protocol UIViewRepresentable: ComponentBase, Equatable {
    associatedtype View: UIView
    func create() -> View
    func update(native: View)
}

extension UIViewRepresentable {
    @inline(__always)
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(
            create: {
                [ViewWrapper(creation: self.create)]
            },
            traverse: { (oldValue) in
                if let oldValue = oldValue {
                    if self != oldValue {
                        return [Change(index: 0, difference: .update(self))]
                    }
                    return []
                } else {
                    return [Change(index: 0, difference: .insert(self.asAnyComponent()))]
                }
            },
            update: {
                self.update(native: ($0 as! ViewWrapper<View>).view)
            },
            length: {
                1
            },
            body: self
        )
    }
}

class ViewWrapper<View: UIView>: NativeViewProtocol {
    var creation: () -> View
    lazy var view = self.creation()

    init(creation: @escaping () -> View) {
        self.creation = creation
    }

    @inline(__always)
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(view: view, at: index)
    }

    @inline(__always)
    func unmount(from target: Mountable, at index: Int) {
        target.unmount(view: view, at: index)
    }
}

public protocol UIViewControllerRepresentable: ComponentBase, Equatable {
    associatedtype ViewController: UIViewController
    func create() -> ViewController
    func update(native: ViewController)
}

extension UIViewControllerRepresentable {
    @inline(__always)
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(
            create: {
                [ViewControllerWrapper(creation: self.create)]
            },
            traverse: { (oldValue) -> [Change] in
                if let oldValue = oldValue {
                    if self != oldValue {
                        return [Change(index: 0, difference: .update(self))]
                    }
                    return []
                } else {
                    return [Change(index: 0, difference: .insert(self.asAnyComponent()))]
                }
            },
            update: {
                self.update(native: ($0 as! ViewControllerWrapper<ViewController>).viewController)
            },
            length: {
                1
            },
            body: self
        )
    }
}

class ViewControllerWrapper<ViewController: UIViewController>: NativeViewProtocol {
    var creation: () -> ViewController
    lazy var viewController = self.creation()

    init(creation: @escaping () -> ViewController) {
        self.creation = creation
    }

    @inline(__always)
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(viewController: viewController, at: index, parent: parent)
    }

    @inline(__always)
    func unmount(from target: Mountable, at index: Int) {
        target.unmount(viewController: viewController, at: index)
    }
}
