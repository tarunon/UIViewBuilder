//
//  AnyComponent.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public struct AnyComponent: ComponentBase {
    class Base {
        func _create() -> NativeViewProtocol {
            fatalError()
        }

        func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            fatalError()
        }

        func _update(native: NativeViewProtocol) {
            fatalError()
        }

        func _destroy() -> Differences {
            fatalError()
        }

        func `as`<Content>(_ componentType: Content.Type) -> Content? {
            (self as? Box<Content>)?.content
        }
    }

    class Box<Content>: Base {
        var content: Content
        init(content: Content) {
            self.content = content
        }
    }

    final class NodeBox<Content: NodeComponent>: Box<Content> {
        @inline(__always)
        override func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            content._difference(with: oldValue?.as(Content.self))
        }

        @inline(__always)
        override func _destroy() -> Differences {
            content._destroy()
        }
    }

    final class RepresentableBox<Content: RepresentableBase>: Box<Content> {
        @inline(__always)
        override func _create() -> NativeViewProtocol {
            content.create()
        }

        @inline(__always)
        override func _update(native: NativeViewProtocol) {
            content._update(native: native)
        }

        @inline(__always)
        override func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            if let oldValue = oldValue?.as(Content.self) {
                if !content.isEqual(to: oldValue) {
                    return .update(component: content)
                }
                return .stable(component: content)
            }
            return .insert(component: content)
        }

        @inline(__always)
        override func _destroy() -> Differences {
            .remove(component: content)
        }
    }

    typealias Create<T> = () -> T
    typealias Difference<Component> = (Component?) -> Differences
    typealias Update<T> = (T) -> ()
    typealias Destroy = () -> Differences

    final class ClosureBox<Content: ComponentBase, Native>: Box<Content> {
        var create: Create<Native>
        var difference: Difference<Base>
        var update: Update<Native>
        var destroy: Destroy

        init(create: @escaping Create<Native>, difference: @escaping Difference<Content>, update: @escaping Update<Native>, destroy: @escaping Destroy, content: Content) {
            self.create = create
            self.difference = { difference($0?.as(Content.self)) }
            self.update = update
            self.destroy = destroy
            super.init(content: content)
        }

        @inline(__always)
        override func _create() -> NativeViewProtocol {
            create() as! NativeViewProtocol
        }

        @inline(__always)
        override func _update(native: NativeViewProtocol) {
            update(native as! Native)
        }

        @inline(__always)
        override func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            difference(oldValue)
        }

        @inline(__always)
        override func _destroy() -> Differences {
            destroy()
        }
    }

    let box: Base

    public init<Content: ComponentBase>(@ComponentBuilder creation: () -> Content) {
        self = creation().asAnyComponent()
    }

    init<Content: NodeComponent>(content: Content) {
        self.box = NodeBox(content: content)
    }

    init<Content: RepresentableBase>(content: Content) {
        self.box = RepresentableBox(content: content)
    }

    init<Content: ComponentBase, Native>(create: @escaping Create<Native>, difference: @escaping Difference<Content>, update: @escaping Update<Native>, destroy: @escaping Destroy, content: Content) {
        self.box = ClosureBox(create: create, difference: difference, update: update, destroy: destroy, content: content)
    }

    @inline(__always)
    func _create() -> NativeViewProtocol {
        box._create()
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        box._update(native: native)
    }

    @inline(__always)
    func _difference(with oldValue: AnyComponent?) -> Differences {
        box._difference(with: oldValue?.box)
    }

    @inline(__always)
    func _destroy() -> Differences {
        box._destroy()
    }

    @inline(__always)
    public func asAnyComponent() -> AnyComponent {
        AnyComponent(
            create: self._create,
            difference: self._difference(with:),
            update: self._update(native:),
            destroy: self._destroy,
            content: self
        )
    }
}
