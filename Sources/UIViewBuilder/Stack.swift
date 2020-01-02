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

class NativeStack<Config: StackConfig>: NativeViewProtocol {
    let creation: (NativeViewProtocol?) -> NativeViewProtocol
    lazy var component = self.creation(nil)
    var stackView: UIStackView!

    init(config: Config.Type, creation: @escaping (NativeViewProtocol?) -> NativeViewProtocol, prev: NativeViewProtocol?) {
        self.creation = creation
        self.prev = prev
    }

    var prev: NativeViewProtocol?

    @inline(__always)
    var length: Int {
        stackView.superview == nil ? 0 : 1
    }

    @inline(__always)
    func mount(to target: Mountable, parent: UIViewController) {
        if self.stackView == nil {
            stackView = UIStackView()
            stackView.axis = Config.axis
            target.mount(view: stackView, index: offset)
        }
        component.mount(to: stackView, parent: parent)
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        target.unmount(view: stackView)
    }
}

protocol StackComponent: _Component {
    associatedtype Config: StackConfig
    associatedtype Body: ComponentBase
    associatedtype NativeView = NativeStack<Config>
    var body: Body { get }
}

extension StackComponent where NativeView == NativeStack<Config> {
    @inline(__always)
    func create(prev: NativeViewProtocol?) -> NativeView {
        NativeStack(config: Config.self, creation: self.body.create, prev: prev)
    }

    @inline(__always)
    func update(native: NativeView, oldValue: Self?) -> [Mount] {
        body.update(native: native.component, oldValue: oldValue?.body).map { f in
            return { stackView, native0 in
                f(native.stackView ?? stackView, native0)
            }
        }
    }

    @inline(__always)
    func enumerate() -> [ComponentBase] {
        [self]
    }
}

public struct HStack<Body: ComponentBase>: ComponentBase, StackComponent {
    typealias Config = HStackConfig
    var body: Body

    public init(@ComponentBuilder creation: () -> Body) {
        self.body = creation()
    }
}

public struct VStack<Body: ComponentBase>: ComponentBase, StackComponent {
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

extension UIStackView: Mountable {
    func mount(view: UIView, index: Int) {
        insertArrangedSubview(view, at: index)
    }

    func mount(viewController: UIViewController, index: Int, parent: UIViewController) {
        insertArrangedViewController(viewController, at: index, parentViewController: parent)
    }

    func unmount(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func unmount(viewController: UIViewController) {
        removeArrangedViewController(viewController)
    }
}
