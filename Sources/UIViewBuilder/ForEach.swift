//
//  ForEach.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

class NativeForEach: NativeViewProtocol {
    var list: [NativeViewProtocol]
    var reuseQueue: [NativeViewProtocol] = []

    var length: Int { list.map { $0.length }.reduce(0, +) }
    var prev: NativeViewProtocol?

    init(list: [NativeViewProtocol], prev: NativeViewProtocol?) {
        self.list = list
        self.prev = prev
    }

    @inline(__always)
    func mount(to stackView: UIStackView, parent: UIViewController) {
        list.forEach { (native) in
            native.mount(to: stackView, parent: parent)
        }
    }

    @inline(__always)
    func unmount(from stackView: UIStackView) {
        list.forEach { element in
            element.unmount(from: stackView)
        }
        reuseQueue += list
        list = []
    }

    @inline(__always)
    func mountElement(element: NativeViewProtocol, at index: Int) -> Mount {
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

    @inline(__always)
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

    @inline(__always)
    func reuseElement<Component: ComponentBase>(component: Component) -> (NativeViewProtocol, [Mount])? {
        guard let element = reuseQueue.popLast() else {
            return nil
        }
        return (element, component.update(native: element, oldValue: nil))
    }
}

public struct ForEach<Component: ComponentBase>: ComponentBase, _Component where Component: Equatable {
    typealias NativeView = NativeForEach
    var components: [Component]
    public init<T>(_ elements: [T], _ f: (T) -> Component) {
        self.components = elements.map(f)
    }

    @inline(__always)
    func create(prev: NativeViewProtocol?) -> NativeForEach {
        NativeView(
            list: components.reduce(into: (prev, [NativeViewProtocol]())) { (result, component) in
                result.1.append(component.create(prev: result.0))
                result.0 = result.1.last
            }.1,
            prev: prev
        )
    }

    @inline(__always)
    func update(native: NativeForEach, oldValue: ForEach<Component>?) -> [Mount] {
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


    @inline(__always)
    func updateWithoutDifference(native: NativeForEach, oldValue: ForEach<Component>?) -> [Mount] {
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
