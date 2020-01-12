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

        func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            fatalError()
        }

        func _update(native: NativeViewProtocol) {
            fatalError()
        }

        func _length() -> Int {
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
        override func _difference(with oldValue: AnyComponent.Base?) -> Differences {
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
    }

    typealias Create = () -> [NativeViewProtocol]
    typealias DifferenceFunc<Component> = (Component?) -> Differences
    typealias Update = (NativeViewProtocol) -> ()
    typealias Length = () -> Int

    final class ClosureBox<Content: ComponentBase>: Box<Content> {
        var create: Create
        var difference: DifferenceFunc<Base>
        var update: Update
        var length: Length

        init(create: @escaping Create, difference: @escaping DifferenceFunc<Content>, update: @escaping Update, length: @escaping Length, content: Content) {
            self.create = create
            self.difference = { difference($0?.as(Content.self)) }
            self.update = update
            self.length = length
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
        override func _difference(with oldValue: AnyComponent.Base?) -> Differences {
            difference(oldValue)
        }

        @inline(__always)
        override func _length() -> Int {
            length()
        }
    }

    let box: Base

    public init<Content: ComponentBase>(@ComponentBuilder creation: () -> Content) {
        self = creation().asAnyComponent()
    }

    init<Content: ComponentBase & _Component>(content: Content) {
        self.box = GenericBox(content: content)
    }

    init<Content: ComponentBase>(create: @escaping Create, difference: @escaping DifferenceFunc<Content>, update: @escaping Update, length: @escaping Length, content: Content) {
        self.box = ClosureBox(create: create, difference: difference, update: update, length: length, content: content)
    }

    init<Content: NativeRepresentable>(content: Content) where Content.Native: NativeViewProtocol {
        self.box = ClosureBox(
            create: { [content.create()] },
            difference: content.difference,
            update: { content.update(native: $0 as! Content.Native) },
            length: { 1 },
            content: content
        )
    }

    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        box._create()
    }

    @inline(__always)
    func _difference(with oldValue: AnyComponent?) -> Differences {
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
}
