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

private extension ComponentBase {
    func _modifier<Modifier: ComponentModifier>(modifier: Modifier) -> ComponentBase {
        return self.modifier(modifier: modifier)
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
            applyToView: { _ in },
            applyToViewController: { _ in },
            bodyFunc: body,
            modifier: self
        )
    }
}

protocol _ComponentModifier {
    func _apply(to view: UIView)
    func _apply(to viewController: UIViewController)
}

extension _ComponentModifier where Self: ComponentModifier {
    func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(modifier: self)
    }
}

extension Difference {
    func with<Modifier: ComponentModifier>(modifier: Modifier, changed: Bool) -> Difference {
        switch self.change {
        case .insert(let component):
            return Difference(index: index, change: .insert(component._modifier(modifier: modifier)))
        case .update(let component),
             .stable(let component) where changed:
            return Difference(index: index, change: .update(component._modifier(modifier: modifier)))
        case .remove(let component):
            return Difference(index: index, change: .remove(component._modifier(modifier: modifier)))
        case .stable(let component):
            return Difference(index: index, change: .stable(component._modifier(modifier: modifier)))
        }
    }
}

class NativeModifiedContent<Content: ComponentBase, Modifier: ComponentModifier>: NativeViewProtocol, Mountable {
    var body: Modifier.Body {
        didSet {
            update(differences: body.difference(with: oldValue), natives: &natives, cache: nil, parent: viewController)
        }
    }

    var modifier: Modifier {
        didSet {
            if modifier.isEqual(to: oldValue) { return }
            natives.forEach { $0.unmount(from: self) }
            natives.enumerated().forEach { $0.element.mount(to: self, at: $0.offset, parent: viewController) }
        }
    }
    lazy var natives = lazy(type: [NativeViewProtocol].self) {
        var natives = [NativeViewProtocol]()
        update(differences: body.difference(with: nil), natives: &natives, cache: nil, parent: self.viewController)
        return natives
    }
    weak var viewController: UIViewController!
    weak var target: Mountable!
    var index: Int!

    init(content: Content, modifier: Modifier) {
        self.body = modifier.body(content: content.asAnyComponent())
        self.modifier = modifier
    }

    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        self.target = target
        self.viewController = parent
        self.index = index
        natives.enumerated().forEach { $0.element.mount(to: self, at: $0.offset, parent: parent) }
    }

    func unmount(from target: Mountable) {
        natives.forEach { $0.unmount(from: self) }
    }

    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        modifier.asAnyComponentModifier()._apply(to: viewController)
        modifier.asAnyComponentModifier()._apply(to: viewController.view)
        target.mount(viewController: viewController, at: self.index + index, parent: parent)
    }

    func mount(view: UIView, at index: Int) {
        modifier.asAnyComponentModifier()._apply(to: viewController)
        modifier.asAnyComponentModifier()._apply(to: view)
        target.mount(view: view, at: self.index + index)
    }

    func unmount(viewController: UIViewController) {
        target.unmount(viewController: viewController)
    }

    func unmount(view: UIView) {
        target.unmount(view: view)
    }
}

public struct ModifiedContent<Content: ComponentBase, Modifier: ComponentModifier>: ComponentBase, _NativeRepresentable {
    typealias Native = NativeModifiedContent<Content, Modifier>

    public var content: Content
    public var modifier: Modifier

    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    @inline(__always)
    func create() -> NativeModifiedContent<Content, Modifier> {
        NativeModifiedContent(content: content, modifier: modifier)
    }

    @inline(__always)
    func update(native: NativeModifiedContent<Content, Modifier>) {
        native.body = modifier.body(content: content.asAnyComponent())
        native.modifier = modifier
    }

    @inline(__always)
    func _length() -> Int {
        content.length()
    }

    @inline(__always)
    func _difference(with oldValue: Self?) -> [Difference] {
        content.difference(with: oldValue?.content).map {
            $0.with(modifier: modifier, changed: !self.modifier.isEqual(to: oldValue?.modifier))
        }
    }
}
