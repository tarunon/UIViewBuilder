//
//  AnyComponent.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

final class AnyNativeView: NativeViewProtocol {
    var body: NativeViewProtocol
    init(body: NativeViewProtocol) {
        self.body = body
    }

    @inline(__always)
    var prev: NativeViewProtocol? {
        get {
            body.prev
        }
        set {
            body.prev = newValue
        }
    }

    @inline(__always)
    var length: Int {
        body.length
    }

    @inline(__always)
    func mount(to target: Mountable, parent: UIViewController) {
        body.mount(to: target, parent: parent)
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        body.unmount(from: target)
    }
}

public struct AnyComponent: ComponentBase, _Component {
    typealias NativeView = AnyNativeView

    class Base: _Component {
        func create(prev: NativeViewProtocol?) -> AnyNativeView {
            fatalError()
        }

        func update(native: AnyNativeView, oldValue: Base?) -> [Mount] {
            fatalError()
        }

        func enumerate() -> [ComponentBase] {
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
        override func create(prev: NativeViewProtocol?) -> AnyNativeView {
            AnyNativeView(body: body.create(prev: prev))
        }

        @inline(__always)
        override func update(native: AnyNativeView, oldValue: Base?) -> [Mount] {
            body.update(native: native.body as! Body.NativeView, oldValue: oldValue?.as(Body.self))
        }

        @inline(__always)
        override func enumerate() -> [ComponentBase] {
            body.enumerate()
        }
    }

    final class ClosureBox<Body: ComponentBase>: Box<Body> {
        var _create: (NativeViewProtocol?) -> AnyNativeView
        var _update: (AnyNativeView, AnyComponent?) -> [Mount]
        var _enumerate: () -> [ComponentBase]

        init<NativeView: NativeViewProtocol>(create: @escaping (NativeViewProtocol?) -> NativeView, update: @escaping (NativeView, Body?) -> [Mount], enumerate: @escaping () -> [ComponentBase], body: Body) {
            self._create = { AnyNativeView(body: create($0)) }
            self._update = { update($0.body as! NativeView, $1?.box.as(Body.self)) }
            self._enumerate = enumerate
            super.init(body: body)
        }

        @inline(__always)
        override func create(prev: NativeViewProtocol?) -> AnyNativeView {
            _create(prev)
        }

        @inline(__always)
        override func update(native: AnyNativeView, oldValue: Base?) -> [Mount] {
            _update(native, oldValue.map(AnyComponent.init))
        }

        @inline(__always)
        override func enumerate() -> [ComponentBase] {
            _enumerate()
        }
    }

    let box: Base

    public init<Body: ComponentBase>(@ComponentBuilder creation: () -> Body) {
        self = creation().asAnyComponent()
    }

    init(box: Base) {
        self.box = box
    }

    init<Body: ComponentBase & _Component>(body: Body) {
        self.box = GenericBox(body: body)
    }

    init<NativeView: NativeViewProtocol, Body: ComponentBase>(create: @escaping (NativeViewProtocol?) -> NativeView, update: @escaping (NativeView, Body?) -> [Mount], enumerate: @escaping () -> [ComponentBase], body: Body) {
        self.box = ClosureBox(create: create, update: update, enumerate: enumerate, body: body)
    }

    @inline(__always)
    func create(prev: NativeViewProtocol?) -> AnyNativeView {
        box.create(prev: prev)
    }

    @inline(__always)
    func update(native: AnyNativeView, oldValue: AnyComponent?) -> [Mount] {
        box.update(native: native, oldValue: oldValue?.box)
    }

    @inline(__always)
    func enumerate() -> [ComponentBase] {
        box.enumerate()
    }
}
