//
//  ScrollView.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/05.
//

import UIKit

final class NativeScrollView<Content: ComponentBase>: UIScrollView, NativeViewProtocol, MountableRenderer {
    let cache = NativeViewCache()
    lazy var natives = createNatives()
    var targetParent: UIViewController?
    var oldContent: Content?
    var content: Content {
        didSet {
            updateContent(oldValue: oldValue)
        }
    }
    var needsToUpdateContent: Bool = false
    var axes: Axis.Set {
        didSet {
            if oldValue != self.axes {
                setNeedsUpdateConstraints()
            }
        }
    }

    var widthConstraints = [NSLayoutConstraint]()
    var heightConstraints = [NSLayoutConstraint]()

    init(axes: Axis.Set, content: Content) {
        self.axes = axes
        self.content = content
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        listenProperties()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @inline(__always)
    func deactivateConstraints() {
        NSLayoutConstraint.deactivate(widthConstraints + heightConstraints)
        widthConstraints = []
        heightConstraints = []
    }

    override func layoutSubviews() {
        updateContentIfNeed()
        super.layoutSubviews()
    }

    override func updateConstraints() {
        deactivateConstraints()
        activateConstraints()
        super.updateConstraints()
    }

    @inline(__always)
    func activateConstraints() {
        if #available(iOS 11, *) {
            if !axes.contains(.horizontal) {
                widthConstraints = [
                    widthAnchor.constraint(equalTo: contentLayoutGuide.widthAnchor)
                ]
            }
            if !axes.contains(.vertical) {
                heightConstraints = [
                    heightAnchor.constraint(equalTo: contentLayoutGuide.heightAnchor)
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
                    view.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
                    view.leftAnchor.constraint(equalTo: contentLayoutGuide.leftAnchor),
                    view.rightAnchor.constraint(equalTo: contentLayoutGuide.rightAnchor),
                    view.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor)
                ]
            )
        } else {

        }
    }

    @inline(__always)
    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        insertViewController(viewController, at: index, parentViewController: parent)
        activateConstraints(with: viewController.view)
    }

    @inline(__always)
    func mount(view: UIView, at index: Int) {
        insertSubview(view, at: index)
        activateConstraints(with: view)
    }

    @inline(__always)
    func unmount(viewController: UIViewController) {
        removeViewController(viewController)
    }

    @inline(__always)
    func unmount(view: UIView) {
        view.removeFromSuperview()
    }

    func update(updation: Update) {
        updation.update(.view(self))
    }
}

public struct ScrollView<Content: ComponentBase>: ComponentBase, RepresentableBase, NativeRepresentable {

    typealias Native = NativeScrollView<Content>
    public var axes: Axis.Set
    public var content: Content

    public init(axes: Axis.Set = .vertical, @ComponentBuilder creation: () -> Content) {
        self.axes = axes
        self.content = creation()
    }

    @inline(__always)
    func create() -> NativeScrollView<Content> {
        NativeScrollView(axes: axes, content: content)
    }

    @inline(__always)
    func update(native: NativeScrollView<Content>) {
        native.axes = axes
        native.content = content
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
