//
//  Assets.swift
//  
//
//  Created by tarunon on 2020/01/01.
//

import UIViewBuilder
import UIKit

struct Label: UIViewRepresentable, Equatable {
    var text: String

    func create() -> UILabel {
        let native = UILabel()
        native.translatesAutoresizingMaskIntoConstraints = false
        native.text = text
        return native
    }

    func update(native: UILabel) {
        native.text = text
    }
}

struct TextView: UIViewRepresentable, Equatable {
    var text: String

    func create() -> UITextView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        return textView
    }

    func update(native: UITextView) {
        native.text = text
    }
}

struct Button: Component {
    private struct _Body: UIViewRepresentable, Equatable {
        var text: String

        func create() -> UIButton {
            let native = UIButton()
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

struct Block: UIViewRepresentable, Equatable {
    func create() -> UIView {
        let native = UIView()
        native.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                native.widthAnchor.constraint(equalToConstant: 100),
                native.heightAnchor.constraint(equalToConstant: 100)
            ].map { $0.priority = .defaultLow; return $0 }
        )
        return native
    }

    func update(native: UIView) {
        
    }
}
