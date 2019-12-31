//
//  ComponentProtocol.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

public protocol NativeViewProtocol {
    var prev: NativeViewProtocol? { get }
    var offset: Int { get }
    var length: Int { get }
    func mount(to stackView: UIStackView, parent: UIViewController)
    func unmount(from stackView: UIStackView)
}

public extension NativeViewProtocol {
    var offset: Int {
        prev.map { $0.offset + $0.length } ?? 0
    }
}

public typealias Mount = (UIStackView, UIViewController) -> ()

public protocol _ComponentBase {
    associatedtype NativeView: NativeViewProtocol

    func create(prev: NativeViewProtocol?) -> NativeView
    func update(native: NativeView, oldValue: Self?) -> [Mount]
}

public protocol UIViewRepresentable: _ComponentBase, Equatable {
    associatedtype View: UIView
    associatedtype NativeView = ViewWrapper<View>
    func create() -> View
    func update(native: View)
}

extension UIViewRepresentable where NativeView == ViewWrapper<View> {
    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> NativeView {
        ViewWrapper(creation: create, prev: prev)
    }

    @inline(__always)
    public func update(native: NativeView, oldValue: Self?) -> [Mount] {
        if self != oldValue {
            update(native: native.view!)
        }
        return []
    }
}

public protocol Component: _ComponentBase, Equatable {
    associatedtype Body: _ComponentBase
    associatedtype NativeView = Body.NativeView
    var body: Body { get }
}

extension Component {
    public typealias NativeView = Body.NativeView
}

extension Component where NativeView == Body.NativeView {
    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> NativeView {
        body.create(prev: prev)
    }

    @inline(__always)
    public func update(native: NativeView, oldValue: Self?) -> [Mount] {
        if self != oldValue {
            return body.update(native: native, oldValue: oldValue?.body)
        }
        return []
    }
}

public class ViewControllerWrapper<ViewController: UIViewController>: NativeViewProtocol {
    var creation: () -> ViewController
    var viewController: ViewController?
    public var prev: NativeViewProtocol?

    init(creation: @escaping () -> ViewController, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    @inline(__always)
    public var length: Int { 1 }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        if let viewController = viewController {
            viewController.view.isHidden = false
        } else {
            viewController = creation()
            stackView.insertArrangedViewController(viewController!, at: offset, parentViewController: parent)
        }
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        viewController?.view.isHidden = true
    }
}

public class ViewWrapper<View: UIView>: NativeViewProtocol {
    var creation: () -> View
    var view: View?
    public var prev: NativeViewProtocol?

    init(creation: @escaping () -> View, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    @inline(__always)
    public var length: Int { 1 }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        if let view = view {
            view.isHidden = false
        } else {
            view = creation()
            stackView.insertArrangedSubview(view!, at: offset)
        }
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        view?.isHidden = true
    }
}
