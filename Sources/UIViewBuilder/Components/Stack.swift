//
//  Stack.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

protocol StackConfig {
    static var axis: Axis { get }
}

struct HStackConfig: StackConfig {
    public static let axis = Axis.horizontal
}

struct VStackConfig: StackConfig {
    public static let axis = Axis.vertical
}

final class NativeStack<Content: ComponentBase, Config: StackConfig>: NativeViewProtocol, Mountable {
    var content: Content {
        didSet {
            update(differences: content.difference(with: oldValue), natives: &natives, cache: cache, parent: parent)
        }
    }
    let cache = NativeViewCache()
    lazy var natives = lazy(type: [NativeViewProtocol].self) {
        var natives = [NativeViewProtocol]()
        update(differences: self.content.difference(with: nil), natives: &natives, cache: cache, parent: parent)
        return natives
    }
    lazy var stackView = lazy(type: UIStackView.self) {
        let stackView = UIStackView()
        stackView.axis = Config.axis.nativeLayoutConstraint
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
    var parent: UIViewController!

    init(config: Config.Type, content: Content) {
        self.content = content
    }

    @inline(__always)
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        self.parent = parent
        natives.enumerated().forEach { (index, target) in
            target.mount(to: self, at: index, parent: parent)
        }
        target.mount(view: stackView, at: index)
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        target.unmount(view: stackView)
        natives.reversed().forEach { $0.unmount(from: self) }
    }

    func mount(view: UIView, at index: Int) {
        stackView.insertArrangedSubview(view, at: index)
    }

    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        stackView.insertArrangedViewController(viewController, at: index, parentViewController: parent)
    }

    func unmount(view: UIView) {
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func unmount(viewController: UIViewController) {
        stackView.removeArrangedViewController(viewController)
    }
}

protocol StackComponent: _NativeRepresentable where Native == NativeStack<Content, Config> {
    associatedtype Config: StackConfig
    associatedtype Content: ComponentBase
    var content: Content { get }
}

extension StackComponent {
    @inline(__always)
    func create() -> NativeStack<Content, Config> {
        NativeStack(config: Config.self, content: content)
    }

    @inline(__always)
    func update(native: NativeStack<Content, Config>) {
        native.content = content
    }
}

public struct HStack<Content: ComponentBase>: ComponentBase, StackComponent {
    typealias Config = HStackConfig
    public var content: Content

    public init(@ComponentBuilder creation: () -> Content) {
        self.content = creation()
    }
}

public struct VStack<Content: ComponentBase>: ComponentBase, StackComponent {
    typealias Config = VStackConfig
    public var content: Content

    public init(@ComponentBuilder creation: () -> Content) {
        self.content = creation()
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
