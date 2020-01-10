//
//  HostingController.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/01.
//

import UIKit

public class _HostingController<Component: ComponentBase>: UIViewController, Mountable {
    class View: UIView {
        weak var parent: _HostingController?
        lazy var stackView = lazy(type: UIStackView.self) {
            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            addSubview(stackView)
            NSLayoutConstraint.activate(
                [
                    stackView.topAnchor.constraint(equalTo: topAnchor),
                    stackView.leftAnchor.constraint(equalTo: leftAnchor),
                    stackView.rightAnchor.constraint(equalTo: rightAnchor),
                    stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ]
            )
            return stackView
        }
        init(parent: _HostingController) {
            self.parent = parent
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            if let parent = parent, parent.oldComponent != nil {
                parent.update(differences: parent.component.difference(with: parent.oldComponent), natives: &parent.natives, cache: parent.cache, parent: parent)
                parent.oldComponent = nil
            }
            super.layoutSubviews()
        }
    }

    let creation: () -> Component
    var oldComponent: Component?
    public lazy var component = self.creation()
    lazy var _view = View(parent: self)
    var natives = [NativeViewProtocol]()
    let cache = NativeViewCache()

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
        view = _view
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        update(differences: component.difference(with: nil), natives: &natives, cache: cache, parent: self)
        oldComponent = nil
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
    }

    func mount(view: UIView, at index: Int) {
        _view.stackView.insertArrangedSubview(view, at: index)
    }

    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        _view.stackView.insertArrangedViewController(viewController, at: index, parentViewController: parent)
    }

    func unmount(view: UIView) {
        _view.stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func unmount(viewController: UIViewController) {
        _view.stackView.removeArrangedViewController(viewController)
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
}
