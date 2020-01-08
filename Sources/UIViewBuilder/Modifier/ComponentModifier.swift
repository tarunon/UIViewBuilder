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
        return ModifiedContent(content: self, modifier: modifier)
    }
}

public protocol ComponentModifier: MaybeEquatable {
    associatedtype Content: ComponentBase
    associatedtype Body: ComponentBase
    func body(content: Content) -> Body
    func asAnyComponentModifier() -> AnyComponentModifier
}

extension ComponentModifier {
    func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(apply: { $0 }, bodyFunc: body, modifier: self)
    }
}

protocol _ComponentModifier: ComponentModifier {
    func _apply(to native: NativeViewProtocol) -> NativeViewProtocol
}

extension _ComponentModifier {
    public func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(modifier: self)
    }
}

extension ComponentModifier where Body == ModifiedContent<Content, Self> {
    func body(content: Content) -> ModifiedContent<Content, Self> {
        ModifiedContent(content: content, modifier: self)
    }
}

protocol NativeViewModifier: _ComponentModifier {
    func apply(to view: UIView) -> NativeViewProtocol
    func apply(to viewController: UIViewController) -> NativeViewProtocol
}

extension NativeViewModifier {
    func _apply(to native: NativeViewProtocol) -> NativeViewProtocol {
        ((native as? UIView).map(apply) ?? (native as? UIViewController).map(apply))!
    }
}

extension ComponentModifier {
    func apply(to native: NativeViewProtocol) -> NativeViewProtocol {
        asAnyComponentModifier()._apply(to: native)
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

public struct ModifiedContent<Content: ComponentBase, Modifier: ComponentModifier>: ComponentBase, _Component {
    public var content: Content
    public var modifier: Modifier

    fileprivate init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        content.create().map(modifier.apply)
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        content.update(native: native)
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

extension ModifiedContent where Modifier: ComponentModifier, Modifier.Content == Content {
    init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
}
