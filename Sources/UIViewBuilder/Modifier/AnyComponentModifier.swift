//
//  AnyComponentModifier.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/07.
//

public struct AnyComponentModifier: ComponentModifier, _ComponentModifier {
    public typealias Content = AnyComponent
    public typealias Body = AnyComponent

    class Base: _ComponentModifier {
        func _apply(to native: NativeViewProtocol) -> NativeViewProtocol {
            fatalError()
        }

        func body(content: AnyComponent) -> AnyComponent {
            fatalError()
        }
    }

    class Box<Modifier: ComponentModifier>: Base {
        var modifier: Modifier
        init(modifier: Modifier) {
            self.modifier = modifier
        }
    }

    final class GenericBox<Modifier: _ComponentModifier>: Box<Modifier> {
        override func _apply(to native: NativeViewProtocol) -> NativeViewProtocol {
            modifier._apply(to: native)
        }

        override func body(content: AnyComponent) -> AnyComponent {
            modifier.body(content: content.box.as(Modifier.Content.self)!).asAnyComponent()
        }
    }

    typealias Apply = (NativeViewProtocol) -> NativeViewProtocol
    typealias BodyFunc<Content, Body> = (Content) -> Body

    final class ClosureBox<Modifier: ComponentModifier>: Box<Modifier> {
        var apply: Apply
        var bodyFunc: BodyFunc<Modifier.Content, Modifier.Body>

        init(apply: @escaping Apply, bodyFunc: @escaping BodyFunc<Modifier.Content, Modifier.Body>, modifier: Modifier) {
            self.apply = apply
            self.bodyFunc = bodyFunc
            super.init(modifier: modifier)
        }

        override func _apply(to native: NativeViewProtocol) -> NativeViewProtocol {
            apply(native)
        }

        override func body(content: AnyComponent) -> AnyComponent {
            bodyFunc(content.box.as(Modifier.Content.self)!).asAnyComponent()
        }
    }

    var box: Base

    init<Modifier: _ComponentModifier>(modifier: Modifier) {
        self.box = GenericBox(modifier: modifier)
    }

    init<Modifier: ComponentModifier>(apply: @escaping Apply, bodyFunc: @escaping BodyFunc<Modifier.Content, Modifier.Body>, modifier: Modifier) {
        self.box = ClosureBox(apply: apply, bodyFunc: bodyFunc, modifier: modifier)
    }

    func _apply(to native: NativeViewProtocol) -> NativeViewProtocol {
        box._apply(to: native)
    }

    public func body(content: AnyComponent) -> AnyComponent {
        box.body(content: content)
    }
}
