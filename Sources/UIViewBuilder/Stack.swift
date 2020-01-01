//
//  Stack.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

public protocol StackConfig {
    static var axis: NSLayoutConstraint.Axis { get }
}

public struct HStackConfig: StackConfig {
    public static let axis: NSLayoutConstraint.Axis = .horizontal
}

public struct VStackConfig: StackConfig {
    public static let axis: NSLayoutConstraint.Axis = .vertical
}

public class _StackView<Config: StackConfig, Native: NativeViewProtocol>: NativeViewProtocol {
    let creation: (NativeViewProtocol?) -> Native
    var component: Native!
    var stackView: UIStackView!

    init(config: Config.Type, creation: @escaping (NativeViewProtocol?) -> Native, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    public var prev: NativeViewProtocol?

    @inline(__always)
    public var length: Int {
        stackView == nil ? component.length : stackView.superview == nil ? 0 : 1
    }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        if stackView.axis == Config.axis {
            if component == nil {
                component = creation(prev)
            }
            component.mount(to: stackView, parent: parent)
        } else {
            if component == nil {
                component = creation(nil)
            }
            if self.stackView == nil {
                self.stackView = UIStackView()
                self.stackView.axis = Config.axis
                stackView.insertArrangedSubview(self.stackView, at: offset)
            }
            _ = component.mount(to: self.stackView, parent: parent)
        }
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        if stackView.axis == Config.axis {
            component.unmount(from: stackView)
        } else {
            stackView.removeArrangedSubview(self.stackView)
            self.stackView.removeFromSuperview()
        }
    }
}

public protocol StackComponent: _ComponentBase {
    associatedtype Config: StackConfig
    associatedtype Body: _ComponentBase
    associatedtype NativeView = _StackView<Config, Body.NativeView>
    var body: Body { get }
}

public extension StackComponent where NativeView == _StackView<Config, Body.NativeView> {
    @inline(__always)
    func create(prev: NativeViewProtocol?) -> NativeView {
        _StackView(config: Config.self, creation: self.body.create, prev: prev)
    }

    @inline(__always)
    func update(native: NativeView, oldValue: Self?) -> [Mount] {
        body.update(native: native.component, oldValue: oldValue?.body).map { f in
            return { stackView, native0 in
                f(native.stackView ?? stackView, native0)
            }
        }
    }
}

public struct HStack<Body: _ComponentBase>: StackComponent {
    public typealias Config = HStackConfig
    public var body: Body

    public init(@ComponentBuilder creation: () -> Body) {
        self.body = creation()
    }
}

public struct VStack<Body: _ComponentBase>: StackComponent {
    public typealias Config = VStackConfig
    public var body: Body

    public init(@ComponentBuilder creation: () -> Body) {
        self.body = creation()
    }
}

extension UIStackView {
    func addArrangedViewController(_ viewController: UIViewController, parentViewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        parentViewController.addChild(viewController)
        addArrangedSubview(viewController.view)
        viewController.didMove(toParent: parentViewController)
    }

    func insertArrangedViewController(_ viewController: UIViewController, at stackIndex: Int, parentViewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        parentViewController.addChild(viewController)
        insertArrangedSubview(viewController.view, at: stackIndex)
        viewController.didMove(toParent: parentViewController)
    }

    func removeArrangedViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        removeArrangedSubview(viewController.view)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}


