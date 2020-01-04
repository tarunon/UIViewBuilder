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

class NativeStack<Body: ComponentBase, Config: StackConfig>: NativeViewProtocol {
    var body: Body {
        didSet {
            update(changes: body.traverse(oldValue: oldValue))
        }
    }
    lazy var natives = self.body.create()
    var stackView: UIStackView!
    var parent: UIViewController!

    init(config: Config.Type, body: Body) {
        self.body = body
    }

    @inline(__always)
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        self.parent = parent
        if stackView == nil {
            stackView = UIStackView()
            stackView.axis = Config.axis
            stackView.translatesAutoresizingMaskIntoConstraints = false
            natives.enumerated().forEach { (index, target) in
                target.mount(to: stackView, at: index, parent: parent)
            }
        }
        target.mount(view: stackView, at: index)
    }

    @inline(__always)
    func unmount(from target: Mountable, at index: Int) {
        target.unmount(view: stackView, at: index)
        natives.enumerated().reversed().forEach { (index, target) in
            target.unmount(from: stackView, at: index)
        }
        natives = []
        stackView = nil
    }

    func update(changes: [Change]) {
        changes.forEach { change in
            switch change.difference {
            case .remove:
                natives[change.index].unmount(from: stackView, at: change.index)
                natives.remove(at: change.index)
            case .insert(let component):
                let native = component.create()[0]
                native.mount(to: stackView, at: change.index, parent: parent)
                natives.insert(native, at: change.index)
            case .update(let component):
                component.asAnyComponent().update(native: natives[change.index])
            }
        }
    }
}

protocol StackComponent: _Component {
    associatedtype Config: StackConfig
    associatedtype Body: ComponentBase
    var body: Body { get }
}

extension StackComponent {
    @inline(__always)
    func create() -> [NativeViewProtocol] {
        [NativeStack(config: Config.self, body: self.body)]
    }

    @inline(__always)
    func traverse(oldValue: Self?) -> [Change] {
        if oldValue != nil {
            return [Change(index: 0, difference: .update(self))]
        }
        return [Change(index: 0, difference: .insert(self))]
    }

    @inline(__always)
    func update(native: NativeViewProtocol) {
        let native = native as! NativeStack<Body, Config>
        native.body = body
    }

    @inline(__always)
    func length() -> Int {
        return 1
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
    func mount(view: UIView, at index: Int) {
        insertArrangedSubview(view, at: index)
    }

    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        insertArrangedViewController(viewController, at: index, parentViewController: parent)
    }

    func unmount(view: UIView?, at index: Int) {
        view.map(removeArrangedSubview)
        view?.removeFromSuperview()
    }

    func unmount(viewController: UIViewController?, at index: Int) {
        viewController.map(removeArrangedViewController)
    }
}
