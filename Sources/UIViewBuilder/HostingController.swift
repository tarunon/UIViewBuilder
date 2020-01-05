//
//  HostingController.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/01.
//

import UIKit

public class _HostingController<Component: ComponentBase>: UIViewController {
    class View: UIView {
        weak var parent: _HostingController?
        lazy var stackView = UIStackView()
        init(parent: _HostingController) {
            self.parent = parent
            super.init(frame: .zero)
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
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            if let parent = parent, parent.oldComponent != nil {
                stackView.update(differences: parent.component.difference(with: parent.oldComponent), natives: &parent.natives, cache: parent.cache, parent: parent)
                parent.oldComponent = nil
            }
            super.layoutSubviews()
        }
    }

    let creation: () -> Component
    var oldComponent: Component?
    public lazy var component = self.creation()
    lazy var _view = View(parent: self)
    lazy var natives = self.component.create()
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
        natives.enumerated().forEach { (index, native) in
            native.mount(to: _view.stackView, at: index, parent: self)
        }
        oldComponent = nil
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
