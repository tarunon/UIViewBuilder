//
//  AnyComponent.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public struct AnyComponent: ComponentBase, _Component {
    class Base: _Component {
        func create() -> [NativeViewProtocol] {
            fatalError()
        }

        func traverse(oldValue: AnyComponent.Base?) -> [Change] {
            fatalError()
        }

        func update(native: NativeViewProtocol) {
            fatalError()
        }

        func length() -> Int {
            fatalError()
        }

        func `as`<Body>(_ componentType: Body.Type) -> Body? {
            (self as? Box<Body>)?.body
        }
    }

    class Box<Body>: Base {
        var body: Body
        init(body: Body) {
            self.body = body
        }
    }

    final class GenericBox<Body: ComponentBase & _Component>: Box<Body> {
        @inline(__always)
        override func create() -> [NativeViewProtocol] {
            body.create()
        }

        @inline(__always)
        override func traverse(oldValue: AnyComponent.Base?) -> [Change] {
            body.traverse(oldValue: oldValue?.as(Body.self))
        }

        @inline(__always)
        override func update(native: NativeViewProtocol) {
            body.update(native: native)
        }

        @inline(__always)
        override func length() -> Int {
            body.length()
        }
    }

    typealias Create = () -> [NativeViewProtocol]
    typealias Traverse<Component> = (Component?) -> [Change]
    typealias Update = (NativeViewProtocol) -> ()
    typealias Length = () -> Int

    final class ClosureBox<Body: ComponentBase>: Box<Body> {
        var _create: Create
        var _traverse: Traverse<Base>
        var _update: Update
        var _length: Length

        init(create: @escaping Create, traverse: @escaping Traverse<Body>, update: @escaping Update, length: @escaping Length, body: Body) {
            self._create = create
            self._traverse = { traverse($0?.as(Body.self)) }
            self._update = update
            self._length = length
            super.init(body: body)
        }

        @inline(__always)
        override func create() -> [NativeViewProtocol] {
            _create()
        }

        @inline(__always)
        override func update(native: NativeViewProtocol) {
            _update(native)
        }

        @inline(__always)
        override func traverse(oldValue: AnyComponent.Base?) -> [Change] {
            _traverse(oldValue)
        }

        @inline(__always)
        override func length() -> Int {
            _length()
        }
    }

    let box: Base

    public init<Body: ComponentBase>(@ComponentBuilder creation: () -> Body) {
        self = creation().asAnyComponent()
    }

    init<Body: ComponentBase & _Component>(body: Body) {
        self.box = GenericBox(body: body)
    }

    init<Body: ComponentBase>(create: @escaping Create, traverse: @escaping Traverse<Body>, update: @escaping Update, length: @escaping Length, body: Body) {
        self.box = ClosureBox(create: create, traverse: traverse, update: update, length: length, body: body)
    }

    @inline(__always)
    func create() -> [NativeViewProtocol] {
        box.create()
    }

    @inline(__always)
    func traverse(oldValue: AnyComponent?) -> [Change] {
        box.traverse(oldValue: oldValue?.box)
    }

    @inline(__always)
    func update(native: NativeViewProtocol) {
        box.update(native: native)
    }

    @inline(__always)
    func length() -> Int {
        box.length()
    }
}
