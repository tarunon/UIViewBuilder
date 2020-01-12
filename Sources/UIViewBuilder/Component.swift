//
//  Component.swift
//  
//
//  Created by tarunon on 2019/12/30.
//

import UIKit

public protocol ComponentBase: MaybeEquatable {
    func asAnyComponent() -> AnyComponent
}

extension ComponentBase {
    @inline(__always)
    func difference(with oldValue: Self?) -> Differences {
        asAnyComponent()._difference(with: oldValue?.asAnyComponent())
    }

    @inline(__always)
    func destroy() -> Differences {
        asAnyComponent()._destroy()
    }
}

protocol NodeComponent: ComponentBase {
    func _difference(with oldValue: Self?) -> Differences
    func _destroy() -> Differences
}

extension NodeComponent {
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(content: self)
    }
}

public protocol Component: ComponentBase {
    associatedtype Body: ComponentBase
    var body: Body { get }
}

extension Component {
    public func asAnyComponent() -> AnyComponent {
        let erased = body.asAnyComponent()
        return AnyComponent(
            create: erased._create,
            difference: { oldValue in
                erased._difference(with: oldValue?.body.asAnyComponent())
            },
            update: erased._update(native:),
            destroy: erased._destroy,
            content: self
        )
    }
}

extension ComponentBase {
    static var reuseIdentifier: String {
        return String(describing: ObjectIdentifier(self))
    }

    var reuseIdentifier: String {
        return Self.reuseIdentifier
    }
}
