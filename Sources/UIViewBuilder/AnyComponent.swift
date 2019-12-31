//
//  AnyComponent.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public struct AnyNativeView: NativeViewProtocol {
    class Base: NativeViewProtocol {
        @inlinable
        var prev: NativeViewProtocol? {
            fatalError()
        }

        @inlinable
        var length: Int {
            fatalError()
        }

        @inlinable
        func mount(to stackView: UIStackView, parent: UIViewController) {
            fatalError()
        }

        @inlinable
        func unmount(from stackView: UIStackView) {
            fatalError()
        }
    }

    class Box<Body: NativeViewProtocol>: Base {
        var body: Body
        init(body: Body) {
            self.body = body
        }

        @inlinable
        override var prev: NativeViewProtocol? {
            body.prev
        }

        @inlinable
        override var length: Int {
            body.length
        }

        @inlinable
        override func mount(to stackView: UIStackView, parent: UIViewController) {
            body.mount(to: stackView, parent: parent)
        }

        @inlinable
        override func unmount(from stackView: UIStackView) {
            body.unmount(from: stackView)
        }
    }

    var box: Base
    public init<Body: NativeViewProtocol>(body: Body) {
        self.box = Box(body: body)
    }

    @inline(__always)
    public var prev: NativeViewProtocol? {
        box.prev
    }

    @inline(__always)
    public var length: Int {
        box.length
    }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        box.mount(to: stackView, parent: parent)
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        box.unmount(from: stackView)
    }
}

public struct AnyComponent: _ComponentBase {
    public typealias NativeView = AnyNativeView
    class Base: _ComponentBase {
        @inlinable
        func create(prev: NativeViewProtocol?) -> AnyNativeView {
            fatalError()
        }

        @inlinable
        func update(native: AnyNativeView, oldValue: AnyComponent.Base?) -> [Mount] {
            fatalError()
        }
    }

    class Box<Body: _ComponentBase>: Base {
        var body: Body
        init(body: Body) {
            self.body = body
        }

        @inlinable
        override func create(prev: NativeViewProtocol?) -> AnyNativeView {
            AnyNativeView(body: body.create(prev: prev))
        }

        @inlinable
        override func update(native: AnyNativeView, oldValue: AnyComponent.Base?) -> [Mount] {
            body.update(native: (native.box as! AnyNativeView.Box<Body.NativeView>).body, oldValue: (oldValue as? Box)?.body)
        }
    }

    var box: Base
    public init<Body: _ComponentBase>(@ComponentBuilder creation: () -> Body) {
        self.box = Box(body: creation())
    }

    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> AnyNativeView {
        box.create(prev: prev)
    }

    @inline(__always)
    public func update(native: AnyNativeView, oldValue: AnyComponent?) -> [Mount] {
        box.update(native: native, oldValue: oldValue?.box)
    }
}
