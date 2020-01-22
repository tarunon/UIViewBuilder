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

final class NativeStack<Content: ComponentBase, Config: StackConfig>: UIStackView, NativeViewProtocol, MountableRenderer {
    lazy var natives = self.createNatives()
    var targetParent: UIViewController?
    var oldContent: Content?
    var content: Content {
        didSet {
            updateContent(oldValue: oldValue)
        }
    }
    let cache: NativeViewCache = NativeViewCache()
    var needsToUpdateContent: Bool = false

    init(config: Config.Type, content: Content) {
        self.content = content
        super.init(frame: .zero)
        axis = Config.axis.nativeLayoutConstraint
        translatesAutoresizingMaskIntoConstraints = false
        listenProperties()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        updateContentIfNeed()
        super.layoutSubviews()
    }

    func mount(view: UIView, at index: Int) {
        insertArrangedSubview(view, at: index)
    }

    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        insertArrangedViewController(viewController, at: index, parentViewController: parent)
    }

    func unmount(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func unmount(viewController: UIViewController) {
        removeArrangedViewController(viewController)
    }

    func update(updation: Update) {
        updation.update(.view(self))
    }
}

protocol StackComponent: NativeRepresentable where Native == NativeStack<Content, Config> {
    associatedtype Config: StackConfig
    associatedtype Content: ComponentBase
    var content: Content { get set }
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

    public var properties: Content.Properties {
        get { content.properties }
        set { content.properties = newValue }
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
