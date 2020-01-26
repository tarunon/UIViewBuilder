//
//  AnyComponent.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public struct AnyComponent: ComponentBase {
    class Base {
        func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            fatalError()
        }

        func _destroy() -> Differences {
            fatalError()
        }

        func `as`<Content>(_ componentType: Content.Type) -> Content? {
            (self as? Box<Content>)?.content
        }

        var properties: AnyDynamicProperty {
            get { fatalError() }
            set { fatalError() }
        }
    }

    class Box<Content>: Base {
        var content: Content
        init(content: Content) {
            self.content = content
        }
    }

    final class NodeBox<Content: NodeComponent & ComponentBase>: Box<Content> {
        @inline(__always)
        override func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            content._difference(with: oldValue?.as(Content.self))
        }

        @inline(__always)
        override func _destroy() -> Differences {
            content._destroy()
        }

        @inline(__always)
        override var properties: AnyDynamicProperty {
            get { AnyDynamicProperty { content.properties } }
            set { content.properties = newValue.body as! Content.Properties }
        }
    }

    final class RepresentableBox<Content: RepresentableBase & ComponentBase>: Box<Content> {
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

        override var properties: AnyDynamicProperty {
            get { AnyDynamicProperty { content.properties } }
            set { content.properties = newValue.body as! Content.Properties }
        }
    }

    typealias Difference<Component> = (Component?) -> Differences
    typealias Destroy = () -> Differences

    final class ClosureBox<Content: ComponentBase>: Box<Content> {
        var difference: Difference<Base>
        var destroy: Destroy

        init(difference: @escaping Difference<Content>, destroy: @escaping Destroy, content: Content) {
            self.difference = { difference($0?.as(Content.self)) }
            self.destroy = destroy
            super.init(content: content)
        }

        @inline(__always)
        override func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            difference(oldValue)
        }

        @inline(__always)
        override func _destroy() -> Differences {
            destroy()
        }

        @inline(__always)
        override var properties: AnyDynamicProperty {
            get { AnyDynamicProperty { content.properties } }
            set { content.properties = newValue.body as! Content.Properties }
        }
    }

    let box: Base

    public init<Content: ComponentBase>(@ComponentBuilder creation: () -> Content) {
        self = creation().asAnyComponent()
    }

    init<Content: NodeComponent & ComponentBase>(content: Content) {
        self.box = NodeBox(content: content)
    }

    init<Content: RepresentableBase & ComponentBase>(content: Content) {
        self.box = RepresentableBox(content: content)
    }

    init<Content: ComponentBase>(difference: @escaping Difference<Content>, destroy: @escaping Destroy, content: Content) {
        self.box = ClosureBox(difference: difference, destroy: destroy, content: content)
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
            difference: self._difference(with:),
            destroy: self._destroy,
            content: self
        )
    }

    public var properties: AnyDynamicProperty {
        get { box.properties }
        set { box.properties = newValue }
    }
}
