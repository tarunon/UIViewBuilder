//
//  NativeModifier.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/09.
//

import UIKit

public struct Update {
    public enum Native {
        case view(UIView)
        case viewController(UIViewController)
    }
    public private (set) var update: (Native) -> ()
    public init(_ update: @escaping (Native) -> ()) {
        self.update = update
    }
    init(_ update: @escaping () -> ()) {
        self.update = { _ in update() }
    }
}

public protocol NativeModifier: ComponentModifier where Body == AnyComponent {
    func modify(_ originalUpdate: Update) -> Update
}

public extension NativeModifier {
    func body(content: AnyComponent) -> AnyComponent {
        content
    }

    func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(
            modify: self.modify(_:),
            bodyFunc: { $0 },
            modifier: self
        )
    }
}
