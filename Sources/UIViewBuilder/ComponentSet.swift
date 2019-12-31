//
//  TableViewCellComposers.swift
//  
//
//  Created by tarunon on 2019/12/03.
//
import UIKit

public enum ComponentSet {
    public struct Empty {}

    public struct Pair<C0, C1> {
        var c0: C0
        var c1: C1
    }

    public enum Either<C0, C1> {
        case c0(C0)
        case c1(C1)
    }
}

extension ComponentSet.Empty: Equatable {}
extension ComponentSet.Pair: Equatable where C0: Equatable, C1: Equatable {}
extension ComponentSet.Either: Equatable where C0: Equatable, C1: Equatable {}

extension ComponentSet.Either where C1 == ComponentSet.Empty {
    init(from optional: C0?) {
        if let value = optional {
            self = .c0(value)
        } else {
            self = .c1(.init())
        }
    }
}

public final class NativeEmpty: NativeViewProtocol {
    public var prev: NativeViewProtocol?

    init(prev: NativeViewProtocol?) {
        self.prev = prev
    }

    @inline(__always)
    public var length: Int {
        0
    }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {

    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {

    }
}

public class NativePair<C0: NativeViewProtocol, C1: NativeViewProtocol>: NativeViewProtocol {
    var c0: C0?
    var c1: C1?

    public var prev: NativeViewProtocol?

    init(c0: C0?, c1: C1?, prev: NativeViewProtocol?) {
        self.c0 = c0
        self.c1 = c1
        self.prev = prev
    }

    public var length: Int {
        (c0?.length ?? 0) + (c1?.length ?? 0)
    }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        if let c0 = c0 {
            c0.mount(to: stackView, parent: parent)
        }
        if let c1 = c1 {
            c1.mount(to: stackView, parent: parent)
        }
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        c0?.unmount(from: stackView)
        c1?.unmount(from: stackView)
    }
}

extension ComponentSet.Empty: _ComponentBase {
    public typealias NativeView = NativeEmpty

    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> NativeEmpty {
        .init(prev: prev)
    }

    @inline(__always)
    public func update(native: NativeEmpty, oldValue: ComponentSet.Empty?) -> [Mount] {
        []
    }
}

extension ComponentSet.Pair: _ComponentBase where C0: _ComponentBase, C1: _ComponentBase {
    public typealias NativeView = NativePair<C0.NativeView, C1.NativeView>

    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> NativePair<C0.NativeView, C1.NativeView> {
        let native0 = c0.create(prev: prev)
        let native1 = c1.create(prev: native0)
        return NativePair(c0: native0, c1: native1, prev: prev)
    }

    @inline(__always)
    public func update(native: NativePair<C0.NativeView, C1.NativeView>, oldValue: ComponentSet.Pair<C0, C1>?) -> [Mount] {
        c0.update(native: native.c0!, oldValue: oldValue?.c0)
            + c1.update(native: native.c1!, oldValue: oldValue?.c1)
    }
}

extension ComponentSet.Either: _ComponentBase where C0: _ComponentBase, C1: _ComponentBase {
    public typealias NativeView = NativePair<C0.NativeView, C1.NativeView>

    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> NativePair<C0.NativeView, C1.NativeView> {
        switch self {
        case .c0(let c0):
            return .init(c0: c0.create(prev: prev), c1: nil, prev: prev)
        case .c1(let c1):
            return .init(c0: nil, c1: c1.create(prev: prev), prev: prev)
        }
    }

    @inline(__always)
    public func update(native: NativePair<C0.NativeView, C1.NativeView>, oldValue: ComponentSet.Either<C0, C1>?) -> [Mount] {
        switch (self, oldValue) {
        case (.c0(let c0), .c0(let oldValue0)):
            return c0.update(native: native.c0!, oldValue: oldValue0)
        case (.c1(let c1), .c1(let oldValue1)):
            return c1.update(native: native.c1!, oldValue: oldValue1)
        case (.c0(let c0), _):
            var mounts = [Mount]()
            if let native0 = native.c0 {
                mounts += c0.update(native: native0, oldValue: nil)
            } else {
                native.c0 = c0.create(prev: native.prev)
            }
            return mounts + [
                { stackView, parent in
                    native.c1?.unmount(from: stackView)
                    native.c0?.mount(to: stackView, parent: parent)
                }
            ]
        case (.c1(let c1), _):
            var mounts = [Mount]()
            if let native1 = native.c1 {
                 mounts += c1.update(native: native1, oldValue: nil)
            } else {
                native.c1 = c1.create(prev: native.prev)
            }
            return mounts + [
                { stackView, parent in
                    native.c0?.unmount(from: stackView)
                    native.c1?.mount(to: stackView, parent: parent)
                }
            ]
        }
    }
}
