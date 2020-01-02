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
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(
            create: { prev in
                ViewWrapper(creation: self.create, prev: prev)
            },
            update: { (native, oldValue) in
                if self != oldValue {
                    self.update(native: native.view)
                }
                return []
            },
            body: self
        )
    }
}

class ViewWrapper<View: UIView>: NativeViewProtocol {
    var creation: () -> View
    lazy var view = self.creation()
    var prev: NativeViewProtocol?

    init(creation: @escaping () -> View, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    @inline(__always)
    var length: Int { view.superview == nil ? 0 : 1 }

    @inline(__always)
    func mount(to stackView: UIStackView, parent: UIViewController) {
        stackView.insertArrangedSubview(view, at: offset)
    }

    @inline(__always)
    func unmount(from stackView: UIStackView) {
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }
}

public protocol UIViewControllerRepresentable: ComponentBase, Equatable {
    associatedtype ViewController: UIViewController
    func create() -> ViewController
    func update(native: ViewController)
}

extension UIViewControllerRepresentable {
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(
            create: { prev in
                ViewControllerWrapper(creation: self.create, prev: prev)
            },
            update: { (native, oldValue) -> [Mount] in
                if self != oldValue {
                    self.update(native: native.viewController)
                }
                return []
            },
            body: self
        )
    }
}

class ViewControllerWrapper<ViewController: UIViewController>: NativeViewProtocol {
    var creation: () -> ViewController
    lazy var viewController = self.creation()
    var prev: NativeViewProtocol?

    init(creation: @escaping () -> ViewController, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    @inline(__always)
    var length: Int { viewController.view.superview == nil ? 0 : 1 }

    @inline(__always)
    func mount(to stackView: UIStackView, parent: UIViewController) {
        stackView.insertArrangedViewController(viewController, at: offset, parentViewController: parent)
    }

    @inline(__always)
    func unmount(from stackView: UIStackView) {
        stackView.removeArrangedViewController(viewController)
    }
}
