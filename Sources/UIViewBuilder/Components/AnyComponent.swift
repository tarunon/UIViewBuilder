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

        func difference(with oldValue: AnyComponent.Base?) -> [Difference] {
            fatalError()
        }

        func update(native: NativeViewProtocol) {
            fatalError()
        }

        func length() -> Int {
            fatalError()
        }

        func isEqual(to other: AnyComponent.Base?) -> Bool {
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

    final class GenericBox<Content: ComponentBase & _Component>: Box<Content> {
        @inline(__always)
        override func create() -> [NativeViewProtocol] {
            content.create()
        }

        @inline(__always)
        override func difference(with oldValue: AnyComponent.Base?) -> [Difference] {
            content.difference(with: oldValue?.as(Content.self))
        }

        @inline(__always)
        override func update(native: NativeViewProtocol) {
            content.update(native: native)
        }

        @inline(__always)
        override func length() -> Int {
            content.length()
        }

        @inline(__always)
        override func isEqual(to other: Base?) -> Bool {
            content.isEqual(to: other?.as(Content.self))
        }
    }

    typealias Create = () -> [NativeViewProtocol]
    typealias Traverse<Component> = (Component?) -> [Difference]
    typealias Update = (NativeViewProtocol) -> ()
    typealias Length = () -> Int
    typealias IsEqualTo<Component> = (Component?) -> Bool

    final class ClosureBox<Content: ComponentBase>: Box<Content> {
        var _create: Create
        var _traverse: Traverse<Base>
        var _update: Update
        var _length: Length
        var _isEqualTo: IsEqualTo<Base>

        init(create: @escaping Create, traverse: @escaping Traverse<Content>, update: @escaping Update, length: @escaping Length, isEqualTo: @escaping IsEqualTo<Content>, content: Content) {
            self._create = create
            self._traverse = { traverse($0?.as(Content.self)) }
            self._update = update
            self._length = length
            self._isEqualTo = { isEqualTo($0?.as(Content.self)) }
            super.init(content: content)
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
        override func difference(with oldValue: AnyComponent.Base?) -> [Difference] {
            _traverse(oldValue)
        }

        @inline(__always)
        override func length() -> Int {
            _length()
        }


        @inline(__always)
        override func isEqual(to other: Base?) -> Bool {
            _isEqualTo(other)
        }
    }

    let box: Base

    public init<Content: ComponentBase>(@ComponentBuilder creation: () -> Content) {
        self = creation().asAnyComponent()
    }

    init<Content: ComponentBase & _Component>(content: Content) {
        self.box = GenericBox(content: content)
    }

    init<Content: ComponentBase>(create: @escaping Create, traverse: @escaping Traverse<Content>, update: @escaping Update, length: @escaping Length, isEqualTo: @escaping IsEqualTo<Content>, content: Content) {
        self.box = ClosureBox(create: create, traverse: traverse, update: update, length: length, isEqualTo: isEqualTo, content: content)
    }

    init<Content: NativeRepresentable>(content: Content) where Content.Native: NativeViewProtocol {
        self.box = ClosureBox(
            create: { [content.create()] },
            traverse: content.traverse,
            update: { content.update(native: $0 as! Content.Native) },
            length: { 1 },
            isEqualTo: { _ in false },
            content: content
        )
    }

    init<Content: NativeRepresentable & Equatable>(content: Content) where Content.Native: NativeViewProtocol {
        self.box = ClosureBox(
            create: { [content.create()] },
            traverse: content.traverse,
            update: { content.update(native: $0 as! Content.Native) },
            length: { 1 },
            isEqualTo: { content == $0 },
            content: content
        )
    }

    @inline(__always)
    func create() -> [NativeViewProtocol] {
        box.create()
    }

    @inline(__always)
    func difference(with oldValue: AnyComponent?) -> [Difference] {
        box.difference(with: oldValue?.box)
    }

    @inline(__always)
    func update(native: NativeViewProtocol) {
        box.update(native: native)
    }

    @inline(__always)
    func length() -> Int {
        box.length()
    }

    @inline(__always)
    func isEqual(to other: AnyComponent?) -> Bool {
        box.isEqual(to: other?.box)
    }
}
