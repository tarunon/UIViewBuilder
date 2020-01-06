//
//  AnyComponent.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public struct AnyComponent: ComponentBase, _Component {
    class Base: _Component {
        func _create() -> [NativeViewProtocol] {
            fatalError()
        }

        func _difference(with oldValue: AnyComponent.Base?) -> [Difference] {
            fatalError()
        }

        func _update(native: NativeViewProtocol) {
            fatalError()
        }

        func _length() -> Int {
            fatalError()
        }

        func _isEqual(to other: AnyComponent.Base?) -> Bool {
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
        override func _create() -> [NativeViewProtocol] {
            content._create()
        }

        @inline(__always)
        override func _difference(with oldValue: AnyComponent.Base?) -> [Difference] {
            content._difference(with: oldValue?.as(Content.self))
        }

        @inline(__always)
        override func _update(native: NativeViewProtocol) {
            content._update(native: native)
        }

        @inline(__always)
        override func _length() -> Int {
            content._length()
        }

        @inline(__always)
        override func _isEqual(to other: Base?) -> Bool {
            content._isEqual(to: other?.as(Content.self))
        }
    }

    typealias Create = () -> [NativeViewProtocol]
    typealias Traverse<Component> = (Component?) -> [Difference]
    typealias Update = (NativeViewProtocol) -> ()
    typealias Length = () -> Int
    typealias IsEqualTo<Component> = (Component?) -> Bool

    final class ClosureBox<Content: ComponentBase>: Box<Content> {
        var create: Create
        var traverse: Traverse<Base>
        var update: Update
        var length: Length
        var isEqualTo: IsEqualTo<Base>

        init(create: @escaping Create, traverse: @escaping Traverse<Content>, update: @escaping Update, length: @escaping Length, isEqualTo: @escaping IsEqualTo<Content>, content: Content) {
            self.create = create
            self.traverse = { traverse($0?.as(Content.self)) }
            self.update = update
            self.length = length
            self.isEqualTo = { isEqualTo($0?.as(Content.self)) }
            super.init(content: content)
        }

        @inline(__always)
        override func _create() -> [NativeViewProtocol] {
            create()
        }

        @inline(__always)
        override func _update(native: NativeViewProtocol) {
            update(native)
        }

        @inline(__always)
        override func _difference(with oldValue: AnyComponent.Base?) -> [Difference] {
            traverse(oldValue)
        }

        @inline(__always)
        override func _length() -> Int {
            length()
        }


        @inline(__always)
        override func _isEqual(to other: Base?) -> Bool {
            isEqualTo(other)
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
    func _create() -> [NativeViewProtocol] {
        box._create()
    }

    @inline(__always)
    func _difference(with oldValue: AnyComponent?) -> [Difference] {
        box._difference(with: oldValue?.box)
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        box._update(native: native)
    }

    @inline(__always)
    func _length() -> Int {
        box._length()
    }

    @inline(__always)
    func _isEqual(to other: AnyComponent?) -> Bool {
        box._isEqual(to: other?.box)
    }
}
