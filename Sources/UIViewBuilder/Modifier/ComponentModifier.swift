//
//  ComponentModifier.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/06.
//

import UIKit

public extension ComponentBase {
    func modifier<Modifier: ComponentModifier>(modifier: Modifier) -> ModifiedContent<Self, Modifier> {
        return ModifiedContent(content: self, modifier: modifier)
    }
}

public protocol ComponentModifier: MaybeEquatable {
    associatedtype Body: ComponentBase
    func body(content: Content) -> Body
    func asAnyComponentModifier() -> AnyComponentModifier
}

public extension ComponentModifier {
    typealias Content = AnyComponent
    func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(
            modify: { $0 },
            bodyFunc: body,
            modifier: self
        )
    }
}

extension ComponentModifier {
    func modify(_ originalUpdate: Update) -> Update {
        asAnyComponentModifier()._modify(originalUpdate)
    }
}

class NativeModifiedContent<Component: RepresentableBase, Modifier: ComponentModifier>: NativeViewRenderer {

    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        native.mount(to: target, at: index, parent: parent)
    }

    func unmount(from target: Mountable) {
        native.unmount(from: target)
    }

    func update() {
        native.update(updation: source.modifier.modify(Update {
            self.content.difference(with: self.oldContent).differences[0].component.update(native: self.native)
        }))
    }

    lazy var native = lazy(type: NativeViewProtocol.self) {
        let native = self.content.difference(with: self.oldContent).differences[0].component.create()
        native.update(updation: source.modifier.modify(Update{}))
        return native
    }

    var oldContent: Modifier.Body?
    var content: Modifier.Body

    var source: (content: Component, modifier: Modifier) {
        didSet {
            self.content = source.modifier.body(content: source.content.asAnyComponent())
        }
    }

    var needsToUpdateContent: Bool = false

    init(content: Component, modifier: Modifier) {
        self.source = (content, modifier)
        self.content = source.modifier.body(content: source.content.asAnyComponent())
    }

    func setNeedsLayout() {
        self.updateContentIfNeed()
    }

    func update(updation: Update) {
        native.update(updation: updation)
    }
}

struct _ModifiedContent<Content: RepresentableBase, Modifier: ComponentModifier>: ComponentBase, NativeRepresentable {
    typealias Native = NativeModifiedContent<Content, Modifier>

    var content: Content
    var modifier: Modifier

    func create() -> NativeModifiedContent<Content, Modifier> {
        .init(content: content, modifier: modifier)
    }

    func update(native: NativeModifiedContent<Content, Modifier>) {
        native.source = (content, modifier)
    }
}

public struct ModifiedContent<Content: ComponentBase, Modifier: ComponentModifier>: ComponentBase, NodeComponent {

    public typealias Properties = Content.Properties

    public var content: Content
    public var modifier: Modifier

    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    public var properties: Properties {
        get {
            content.properties
        }
        set {
            content.properties = newValue
        }
    }

    @inline(__always)
    func _difference(with oldValue: Self?) -> Differences {
        content.difference(with: oldValue?.content).with(modifier: modifier, changed: !self.modifier.isEqual(to: oldValue?.modifier))
    }

    func _destroy() -> Differences {
        content.destroy().with(modifier: modifier, changed: false)
    }
}
