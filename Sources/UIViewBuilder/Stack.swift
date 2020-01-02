//
//  Stack.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

protocol StackConfig {
    static var axis: NSLayoutConstraint.Axis { get }
}

struct HStackConfig: StackConfig {
    public static let axis: NSLayoutConstraint.Axis = .horizontal
}

struct VStackConfig: StackConfig {
    public static let axis: NSLayoutConstraint.Axis = .vertical
}

class _StackView<Config: StackConfig>: NativeViewProtocol {
    let creation: (NativeViewProtocol?) -> NativeViewProtocol
    var component: NativeViewProtocol!
    var stackView: UIStackView!

    init(config: Config.Type, creation: @escaping (NativeViewProtocol?) -> NativeViewProtocol, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    var prev: NativeViewProtocol?

    @inline(__always)
    var length: Int {
        stackView == nil ? component.length : stackView.superview == nil ? 0 : 1
    }

    @inline(__always)
    func mount(to stackView: UIStackView, parent: UIViewController) {
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
    func unmount(from stackView: UIStackView) {
        if stackView.axis == Config.axis {
            component.unmount(from: stackView)
        } else {
            stackView.removeArrangedSubview(self.stackView)
            self.stackView.removeFromSuperview()
        }
    }
}

protocol StackComponent {
    associatedtype Config: StackConfig
    associatedtype Body: ComponentBase
    var body: Body { get }
}

extension StackComponent {
    typealias NativeView = _StackView<Config>
}

extension StackComponent {
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

public struct HStack<Body: ComponentBase>: ComponentBase, _Component, StackComponent {
    typealias Config = HStackConfig
    var body: Body

    public init(@ComponentBuilder creation: () -> Body) {
        self.body = creation()
    }
}

public struct VStack<Body: ComponentBase>: ComponentBase, _Component, StackComponent {
    typealias Config = VStackConfig
    var body: Body

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
