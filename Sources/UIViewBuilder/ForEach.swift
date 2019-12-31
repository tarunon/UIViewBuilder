//
//  ForEach.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public class NativeForEach<Native: NativeViewProtocol>: NativeViewProtocol {
    var list: [Native] {
        didSet {
            length = list.map { $0.length }.reduce(0, +)
        }
    }

    public var length: Int
    public var prev: NativeViewProtocol?

    init(list: [Native], prev: NativeViewProtocol?) {
        self.list = list
        self.prev = prev
        self.length = list.map { $0.length }.reduce(0, +)
    }

    @inline(__always)
    public func mount(to stackView: UIStackView, parent: UIViewController) {
        list.forEach { (native) in
            native.mount(to: stackView, parent: parent)
        }
    }

    @inline(__always)
    public func unmount(from stackView: UIStackView) {
        list.forEach { element in
            element.unmount(from: stackView)
        }
    }
}

public struct ForEach<Component: _ComponentBase>: _ComponentBase {
    public typealias NativeView = NativeForEach<Component.NativeView>
    var components: [Component]
    public init<T>(_ elements: [T], _ f: (T) -> Component) {
        self.components = elements.map(f)
    }

    @inline(__always)
    public func create(prev: NativeViewProtocol?) -> NativeForEach<Component.NativeView> {
        NativeView(
            list: components.reduce(into: (prev, [Component.NativeView]())) { (result, component) in
                result.1.append(component.create(prev: result.0))
                result.0 = result.1.last
            }.1,
            prev: prev
        )
    }

    @inline(__always)
    public func update(native: NativeForEach<Component.NativeView>, oldValue: ForEach<Component>?) -> [Mount] {
        var oldComponents: [Component?] = oldValue?.components ?? []
        let oldCount = oldComponents.count
        if components.count > oldComponents.count {
            oldComponents += Array(repeating: nil, count: components.count - oldComponents.count)
        }
        var mounts = zip(components, zip(native.list, oldComponents))
            .reduce(into: [Mount]()) { (result, value) in
                let (component, (native, oldValue)) = value
                result += component.update(native: native, oldValue: oldValue)
                if oldValue == nil {
                    result += [{ (stackView, parent) in
                        native.mount(to: stackView, parent: parent)
                    }]
                }
        }

        if components.count < oldCount {
            let range = components.count..<oldCount
            mounts += native.list[range].reduce(into: [Mount]()) { (mounts, native) in
                mounts.append({ (stackView, _) in
                    native.unmount(from: stackView)
                })
            }
        }

        if native.list.count < components.count {
            let range = native.list.count..<components.count
            return mounts + components[range].reduce(into: ([Mount]())) { (result, component) in
                let native0 = component.create(prev: native.list.last)
                result.append({ (stackView, parent) in
                    native0.mount(to: stackView, parent: parent)
                })
                native.list.append(native0)
            }
        }
        return mounts
    }
}
