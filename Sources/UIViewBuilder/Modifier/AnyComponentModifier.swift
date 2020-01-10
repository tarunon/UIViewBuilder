//
//  AnyComponentModifier.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/07.
//

import UIKit

public struct AnyComponentModifier: ComponentModifier, _ComponentModifier {
    public typealias Content = AnyComponent
    public typealias Body = AnyComponent

    class Base: _ComponentModifier {
        func _apply(to view: UIView) {
            fatalError()
        }

        func _apply(to viewController: UIViewController) {
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

    final class GenericBox<Modifier: ComponentModifier & _ComponentModifier>: Box<Modifier> {
        override func _apply(to view: UIView) {
            modifier._apply(to: view)
        }

        override func _apply(to viewController: UIViewController) {
            modifier._apply(to: viewController)
        }

        override func body(content: AnyComponent) -> AnyComponent {
            modifier.body(content: content.box.as(Modifier.Content.self)!).asAnyComponent()
        }
    }

    typealias Apply<T> = (T) -> ()
    typealias BodyFunc<Content, Body> = (Content) -> Body

    final class ClosureBox<Modifier: ComponentModifier>: Box<Modifier> {
        var applyToView: Apply<UIView>
        var applyToViewController: Apply<UIViewController>
        var bodyFunc: BodyFunc<Modifier.Content, Modifier.Body>

        init(applyToView: @escaping Apply<UIView>, applyToViewController: @escaping Apply<UIViewController>, bodyFunc: @escaping BodyFunc<Modifier.Content, Modifier.Body>, modifier: Modifier) {
            self.applyToView = applyToView
            self.applyToViewController = applyToViewController
            self.bodyFunc = bodyFunc
            super.init(modifier: modifier)
        }

        override func _apply(to view: UIView) {
            applyToView(view)
        }

        override func _apply(to viewController: UIViewController) {
            applyToViewController(viewController)
        }

        override func body(content: AnyComponent) -> AnyComponent {
            bodyFunc(content.box.as(Modifier.Content.self)!).asAnyComponent()
        }
    }

    var box: Base

    init<Modifier: ComponentModifier & _ComponentModifier>(modifier: Modifier) {
        self.box = GenericBox(modifier: modifier)
    }

    init<Modifier: ComponentModifier>(applyToView: @escaping Apply<UIView>, applyToViewController: @escaping Apply<UIViewController>, bodyFunc: @escaping BodyFunc<Modifier.Content, Modifier.Body>, modifier: Modifier) {
        self.box = ClosureBox(applyToView: applyToView, applyToViewController: applyToViewController, bodyFunc: bodyFunc, modifier: modifier)
    }

    func _apply(to view: UIView) {
        box._apply(to: view)
    }

    func _apply(to viewController: UIViewController) {
        box._apply(to: viewController)
    }

    public func body(content: AnyComponent) -> AnyComponent {
        box.body(content: content)
    }

    public func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(modifier: self)
    }
}
