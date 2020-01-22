//
//  AnyComponentModifier.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/07.
//

import UIKit

public struct AnyComponentModifier: ComponentModifier {
    public typealias Content = AnyComponent
    public typealias Body = AnyComponent

    class Base {
        func _modify(_ originalUpdate: Update) -> Update {
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

    typealias Modify<T> = (T) -> T
    typealias BodyFunc<Body> = (AnyComponent) -> Body

    final class ClosureBox<Modifier: ComponentModifier, Body: ComponentBase>: Box<Modifier> {
        var modify: Modify<Update>
        var bodyFunc: BodyFunc<Body>

        init(modify: @escaping Modify<Update>, bodyFunc: @escaping BodyFunc<Body>, modifier: Modifier) {
            self.modify = modify
            self.bodyFunc = bodyFunc
            super.init(modifier: modifier)
        }

        override func _modify(_ originalUpdate: Update) -> Update {
            modify(originalUpdate)
        }

        override func body(content: AnyComponent) -> AnyComponent {
            bodyFunc(content).asAnyComponent()
        }
    }

    var box: Base

    init<Modifier: ComponentModifier, Body: ComponentBase>(modify: @escaping Modify<Update>, bodyFunc: @escaping BodyFunc<Body>, modifier: Modifier) {
        self.box = ClosureBox(modify: modify, bodyFunc: bodyFunc, modifier: modifier)
    }

    func _modify(_ originalUpdate: Update) -> Update {
        box._modify(originalUpdate)
    }


    public func body(content: AnyComponent) -> AnyComponent {
        box.body(content: content)
    }

    public func asAnyComponentModifier() -> AnyComponentModifier {
        AnyComponentModifier(
            modify: _modify,
            bodyFunc: body(content:),
            modifier: self
        )
    }
}
