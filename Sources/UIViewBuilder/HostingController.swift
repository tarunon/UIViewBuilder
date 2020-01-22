//
//  HostingController.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/01.
//

import UIKit

public class _HostingController<Component: ComponentBase>: UIViewController, Mountable {
    let creation: () -> Component
    var oldComponent: Component?
    public lazy var component = self.creation()
    var natives = [NativeViewProtocol]()
    let cache = NativeViewCache()

    lazy var stackView = lazy(type: UIStackView.self) {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }

    public init(@ComponentBuilder creation: @escaping () -> Component) {
        self.creation = creation
        super.init(nibName: nil, bundle: nil)
    }

    public init(_ component: @autoclosure @escaping () -> Component) {
        self.creation = component
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        view = UIView()
        view.addSubview(stackView)
        NSLayoutConstraint.activate(
            [
                stackView.topAnchor.constraint(equalTo: view.topAnchor),
                stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
                stackView.rightAnchor.constraint(equalTo: view.rightAnchor),
                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        )
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        update(graph: component.difference(with: nil), natives: &natives, cache: cache, parent: self)
        oldComponent = nil
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
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

public class HostingController<Component: ComponentBase>: _HostingController<Component> {
    public override var component: Component {
        willSet {
            if oldComponent == nil {
                oldComponent = component
            }
            view.setNeedsLayout()
        }
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if oldComponent != nil {
            update(graph: component.difference(with: oldComponent), natives: &natives, cache: cache, parent: self)
            oldComponent = nil
        }
    }
}
