//
//  ForEach.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public class NativeForEach<Native: NativeViewProtocol>: NativeViewProtocol {
    var list: [Native]
    var reuseQueue: [Native] = []

    public var length: Int { list.map { $0.length }.reduce(0, +) }
    public var prev: NativeViewProtocol?

    init(list: [Native], prev: NativeViewProtocol?) {
        self.list = list
        self.prev = prev
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
        reuseQueue += list
        list = []
    }

    func mountElement(element: Native, at index: Int) -> Mount {
        list.insert(element, at: index)
        var prev = self.prev
        if index > 0 {
            prev = list[index - 1]
        }
        element.prev = prev
        return { (stackView, parent) in
            element.mount(to: stackView, parent: parent)
        }
    }

    func unmountElement(at index: Int) -> Mount {
        let element = list.remove(at: index)
        if index < list.count {
            var prev = self.prev
            if index > 0 {
                prev = list[index - 1]
            }
            list[index].prev = prev
        }
        element.prev = nil
        reuseQueue.append(element)
        return { (stackView, _) in
            element.unmount(from: stackView)
        }
    }

    func reuseElement<Component: _ComponentBase>(component: Component) -> (Native, [Mount])? where Component.NativeView == Native {
        guard let element = reuseQueue.popLast() else {
            return nil
        }
        return (element, component.update(native: element, oldValue: nil))
    }
}

public struct ForEach<Component: _ComponentBase>: _ComponentBase where Component: Equatable {
    public typealias NativeView = NativeForEach<Component.NativeView>
    public var components: [Component]
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
        guard #available(iOS 13, *) else {
            return updateWithoutDifference(native: native, oldValue: oldValue)
        }
        let diff = components.difference(from: oldValue?.components ?? [])
        return diff.reduce(into: [Mount]()) { (mounts, change) in
            switch change {
            case .remove(let offset, _, _):
                mounts.append(native.unmountElement(at: offset))
            case .insert(let offset, let element, _):
                let (native0, mounts0) = native.reuseElement(component: element) ?? (element.create(prev: nil), [])
                mounts += mounts0
                mounts.append(native.mountElement(element: native0, at: offset))
            }
        }
    }

    func updateWithoutDifference(native: NativeForEach<Component.NativeView>, oldValue: ForEach<Component>?) -> [Mount] {
        let oldComponents: [Component] = oldValue?.components ?? []

        var mounts = zip(components, zip(native.list, oldComponents))
            .reduce(into: [Mount]()) { (result, value) in
                let (component, (native, oldValue)) = value
                result += component.update(native: native, oldValue: oldValue)
        }

        if components.count < oldComponents.count {
            let range = components.count..<oldComponents.count
            mounts += range.map { native.unmountElement(at: $0) }
        }

        if native.list.count < components.count {
            let range = native.list.count..<components.count
            mounts += range.reduce(into: [Mount]()) { (mounts, index) in
                let (native0, mounts0) = native.reuseElement(component: components[index]) ?? (components[index].create(prev: nil), [])
                mounts += mounts0
                mounts.append(native.mountElement(element: native0, at: index))
            }
        }
        return mounts
    }
}
