//
//  NativeModifier.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/09.
//

import UIKit

public protocol UIViewModifier: ComponentModifier where Content == Body {
    func apply(to view: UIView)
}

public extension UIViewModifier {
    func body(content: AnyComponent) -> AnyComponent {
        content
    }

    func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(
            applyToView: self.apply(to:),
            applyToViewController: { _ in },
            bodyFunc: self.body(content:),
            modifier: self
        )
    }
}

public protocol UIViewControllerModifier: ComponentModifier where Content == Body {
    func apply(to viewController: UIViewController)
}

public extension UIViewControllerModifier {
    func body(content: AnyComponent) -> AnyComponent {
        content
    }

    func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(
            applyToView: { _ in },
            applyToViewController: self.apply(to:),
            bodyFunc: { $0 },
            modifier: self
        )
    }
}
