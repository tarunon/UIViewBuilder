//
//  HostingController.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/01.
//

import UIKit

public class _HostingController<Component: ComponentBase>: UIViewController, MountableRenderer {

    let creation: () -> Component
    lazy var natives = self.createNatives()
    var oldContent: Component?
    lazy var content: Component = self.creation()
    let cache: NativeViewCache = NativeViewCache()
    var needsToUpdateContent: Bool = false


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
        listenProperties()
        _ = natives
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContentIfNeed()
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
    public var component: Component {
        set { content = newValue }
        get { content }
    }
    public override var content: Component {
        didSet {
            updateContent(oldValue: oldValue)
        }
    }
}
