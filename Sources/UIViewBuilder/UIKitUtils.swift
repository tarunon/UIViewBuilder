//
//  UIKitUtils.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public final class AnyViewController<View: UIView>: UIViewController {
    let creation: (AnyViewController) -> View
    init(creation: @escaping (AnyViewController) -> View) {
        self.creation = creation
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var content: View {
        set {
            super.view = newValue
        }
        get {
            super.view as! View
        }
    }

    override public func loadView() {
        content = creation(self)
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


public class _HostingViewController<Component: _ComponentBase>: UIViewController {
    let creation: () -> Component
    public lazy var component = self.creation()
    lazy var native = self.component.create(prev: nil)
    lazy var stackView = UIStackView()

    public init(_ component: @autoclosure @escaping () -> Component) {
        self.creation = component
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = stackView
        stackView.axis = .vertical
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        _ = native.mount(to: stackView, parent: self)
    }
}

public class HostingViewController<Component: _ComponentBase>: _HostingViewController<Component> {
    public override var component: Component {
        didSet {
            self.component
                .update(native: native, oldValue: oldValue)
                .forEach { f in
                    f(stackView, self)
            }
        }
    }
}

#endif

