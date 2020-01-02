//
//  UIHostingController.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/01.
//

import UIKit

public class _UIHostingController<Component: ComponentBase>: UIViewController {
    class View: UIView {
        weak var parent: _UIHostingController?
        lazy var stackView = UIStackView()
        init(parent: _UIHostingController) {
            self.parent = parent
            super.init(frame: .zero)
            stackView.axis = .vertical
            addSubview(stackView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            if let parent = parent, parent.oldComponent != nil {
                parent.component.update(native: parent.native, oldValue: parent.oldComponent).forEach { f in
                    f(stackView, parent)
                }
                parent.oldComponent = nil
            }
            super.layoutSubviews()
        }
    }

    let creation: () -> Component
    var oldComponent: Component?
    public lazy var component = self.creation()
    lazy var native = self.component.create(prev: nil)
    lazy var _view = View(parent: self)

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
        _ = native.mount(to: _view.stackView, parent: self)
    }
}

public class UIHostingController<Component: ComponentBase>: _UIHostingController<Component> {
    public override var component: Component {
        willSet {
            oldComponent = component
            view.setNeedsLayout()
        }
    }
}
