//
//  Assets.swift
//  Example
//
//  Created by tarunon on 2020/01/05.
//  Copyright © 2020 tarunon. All rights reserved.
//

import UIKit
import UIViewBuilder

struct Label: UIViewRepresentable, Equatable {
    var text: String
    func create() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textAlignment = .center
        return label
    }

    func update(native: UILabel) {
        native.text = text
    }
}

struct Spacer: UIViewRepresentable, Equatable {
    func create() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 16.0).isActive = true
        return view
    }

    func update(native: UIView) {

    }
}

struct Button: Component {
    private struct _Body: UIViewRepresentable, Equatable {
        var text: String

        func create() -> UIButton {
            let native = UIButton(type: .system)
            native.translatesAutoresizingMaskIntoConstraints = false
            native.setTitle(text, for: .normal)
            return native
        }

        func update(native: UIButton) {
            native.setTitle(text, for: .normal)
        }
    }

    private class _Handler: NSObject, UIViewModifier {
        var handler: () -> ()

        init(_ handler: @escaping () -> ()) {
            self.handler = handler
        }

        func apply(to view: UIView) {
            (view as! UIButton).addTarget(self, action: #selector(action), for: .touchUpInside)
        }

        @objc func action() {
            handler()
        }
    }

    var text: String
    var handler: () -> ()

    var body: AnyComponent {
        AnyComponent {
            _Body(text: text).modifier(modifier: _Handler(handler))
        }
    }
}

class ExampleViewController: UIViewController {
    var emoji: [String] {
        didSet {
            contentController.component.emoji = emoji
        }
    }
    lazy var stackView = UIStackView()
    init(emoji: [String]) {
        self.emoji = emoji
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct MyComponent: Component {
        var emoji: [String]
        var handler: () -> ()

        var body: AnyComponent {
            AnyComponent {
                VStack {
                    List {
                        ForEach(data: self.emoji) { text in
                            VStack {
                                Spacer()
                                Label(text: text)
                                Spacer()
                            }
                        }
                    }
                    Button(text: "Shuffle", handler: self.handler)
                    Spacer()
                }
            }
        }
    }

    private (set) lazy var contentController = HostingController {
        MyComponent(emoji: self.emoji, handler: { self.emoji.shuffle() })
    }

    override func loadView() {
        self.view = stackView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(contentController)
        stackView.addArrangedSubview(contentController.view)
        contentController.didMove(toParent: self)
    }
}
