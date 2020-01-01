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

extension UIViewRepresentable {
    public typealias NativeView = ViewWrapper<View>
}

extension UIViewRepresentable where NativeView == ViewWrapper<View> {
    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> NativeView {
        ViewWrapper(creation: create, prev: prev)
    }

    @inline(__always)
    public func update(native: NativeView, oldValue: Self?) -> [Mount] {
        if self != oldValue {
            update(native: native.view)
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
    lazy var viewController = self.creation()
    public var prev: NativeViewProtocol?

    init(creation: @escaping () -> ViewController, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    @inline(__always)
    public var length: Int { viewController.view.superview == nil ? 0 : 1 }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        stackView.insertArrangedViewController(viewController, at: offset, parentViewController: parent)
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        stackView.removeArrangedViewController(viewController)
    }
}

public class ViewWrapper<View: UIView>: NativeViewProtocol {
    var creation: () -> View
    lazy var view = self.creation()
    public var prev: NativeViewProtocol?

    init(creation: @escaping () -> View, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    @inline(__always)
    public var length: Int { view.superview == nil ? 0 : 1 }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        stackView.insertArrangedSubview(view, at: offset)
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }
}
