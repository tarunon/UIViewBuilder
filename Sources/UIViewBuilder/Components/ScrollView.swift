//
//  ScrollView.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/05.
//

import UIKit

final class NativeScrollView<Body: ComponentBase>: NativeViewProtocol, Mountable {
    var axes: AxisSet {
        didSet {
            if oldValue != self.axes {
                deactivateConstraints()
                activateConstraints()
            }
        }
    }
    var body: Body{
        didSet {
            update(differences: body.difference(with: oldValue), natives: &natives, cache: cache, parent: parent)
        }
    }

    let cache = NativeViewCache()
    lazy var natives = self.body.create()
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    var parent: UIViewController!

    var widthConstraints = [NSLayoutConstraint]()
    var heightConstraints = [NSLayoutConstraint]()

    init(axis: AxisSet, body: Body) {
        self.axes = axis
        self.body = body
    }

    @inline(__always)
    func deactivateConstraints() {
        NSLayoutConstraint.deactivate(widthConstraints + heightConstraints)
        widthConstraints = []
        heightConstraints = []
    }

    @inline(__always)
    func activateConstraints() {
        if #available(iOS 11, *) {
            if !axes.contains(.horizontal) {
                widthConstraints = [
                    scrollView.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor)
                ]
            }
            if !axes.contains(.vertical) {
                heightConstraints = [
                    scrollView.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
                ]
            }
        }
        NSLayoutConstraint.activate(heightConstraints + widthConstraints)
    }

    @inline(__always)
    func activateConstraints(with view: UIView) {
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate(
                [
                    view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                    view.leftAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leftAnchor),
                    view.rightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.rightAnchor),
                    view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
                ]
            )
        } else {

        }
    }

    @inline(__always)
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        self.parent = parent
        natives.enumerated().forEach { (index, target) in
            target.mount(to: self, at: index, parent: parent)
        }
        target.mount(view: scrollView, at: index)
        activateConstraints()
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        deactivateConstraints()
        target.unmount(view: scrollView)
        natives.reversed().forEach { $0.unmount(from: self) }
        natives = []
    }

    @inline(__always)
    func length() -> Int {
        return 1
    }

    @inline(__always)
    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        scrollView.insertViewController(viewController, at: index, parentViewController: parent)
        activateConstraints(with: viewController.view)
    }

    @inline(__always)
    func mount(view: UIView, at index: Int) {
        scrollView.insertSubview(view, at: index)
        activateConstraints(with: view)
    }

    @inline(__always)
    func unmount(viewController: UIViewController) {
        scrollView.removeViewController(viewController)
    }

    @inline(__always)
    func unmount(view: UIView) {
        view.removeFromSuperview()
    }
}

public struct AxisSet: OptionSet {
    public var rawValue: Int

    public static let horizontal = AxisSet(rawValue: 1 << 0)
    public static let vertical = AxisSet(rawValue: 1 << 1)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct ScrollView<Body: ComponentBase>: ComponentBase, _Component {
    public var axis: AxisSet
    public var body: Body

    public init(axes: AxisSet = .vertical, @ComponentBuilder creation: () -> Body) {
        self.axis = axes
        self.body = creation()
    }

    @inline(__always)
    func create() -> [NativeViewProtocol] {
        [NativeScrollView(axis: axis, body: body)]
    }

    @inline(__always)
    func difference(with oldValue: Self?) -> [Difference] {
        if oldValue != nil {
            return [Difference(index: 0, change: .update(self))]
        }
        return [Difference(index: 0, change: .insert(self))]
    }

    @inline(__always)
    func update(native: NativeViewProtocol) {
        let native = native as! NativeScrollView<Body>
        native.axes = axis
        native.body = body
    }
}

extension UIScrollView {
    func addViewController(_ viewController: UIViewController, parentViewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        parentViewController.addChild(viewController)
        addSubview(viewController.view)
        viewController.didMove(toParent: parentViewController)
    }

    func insertViewController(_ viewController: UIViewController, at stackIndex: Int, parentViewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        parentViewController.addChild(viewController)
        insertSubview(viewController.view, at: stackIndex)
        viewController.didMove(toParent: parentViewController)
    }

    func removeViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
