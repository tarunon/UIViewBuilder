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
    func mount(to target: Mountable, parent: UIViewController) {
        list.forEach { (native) in
            native.mount(to: target, parent: parent)
        }
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        list.forEach { element in
            element.unmount(from: target)
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
        return { (target, parent) in
            element.mount(to: target, parent: parent)
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
        return { (target, _) in
            element.unmount(from: target)
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

public struct ForEach<Data: RandomAccessCollection, Component: ComponentBase, ID: Equatable>: ComponentBase, _Component where Data.Element: Equatable, Data.Index == Int {
    typealias NativeView = NativeForEach

    public var data: Data

    var creation: (Data.Element) -> Component
    var identify: KeyPath<Data.Element, ID>

    public init(data: Data, identify: KeyPath<Data.Element, ID>, @ComponentBuilder creation: @escaping (Data.Element) -> Component) {
        self.data = data
        self.creation = creation
        self.identify = identify
    }

    @inline(__always)
    func create(prev: NativeViewProtocol?) -> NativeForEach {
        NativeView(
            list: data.map(creation).reduce(into: (prev, [NativeViewProtocol]())) { (result, component) in
                result.1.append(component.create(prev: result.0))
                result.0 = result.1.last
            }.1,
            prev: prev
        )
    }

    @inline(__always)
    func update(native: NativeForEach, oldValue: ForEach?) -> [Mount] {
        guard #available(iOS 13, *) else {
            return updateWithoutDifference(native: native, oldValue: oldValue)
        }
        let oldData = oldValue?.data.map { $0 } ?? []
        let diff = data.map { $0[keyPath: identify] }.difference(from: oldData.map { $0[keyPath: identify] })
        let (fixedOldData, mounts) = diff.reduce(into: (oldData as [Data.Element?], [Mount]())) { (result, change) in
            switch change {
            case .remove(let offset, _, _):
                result.0.remove(at: offset)
                result.1.append(native.unmountElement(at: offset))
            case .insert(let offset, _, _):
                result.0.insert(nil, at: offset)
            }
        }

        return mounts + zip(data, fixedOldData).enumerated().flatMap { (offset, value) -> [Mount] in
            let (element, oldValue) = value
            let component = creation(element)
            if let oldValue = oldValue {
                return component.update(native: native.list[offset], oldValue: creation(oldValue))
            }
            let (native0, mounts0) = native.reuseElement(component: component) ?? (component.create(prev: nil), [])
            return mounts0 + [native.mountElement(element: native0, at: offset)]
        }
    }


    @inline(__always)
    func updateWithoutDifference(native: NativeForEach, oldValue: ForEach?) -> [Mount] {
        let oldData = oldValue?.data.map { $0 } ?? []

        var mounts = zip(data, zip(native.list, oldData))
            .reduce(into: [Mount]()) { (result, value) in
                let (element, (native, oldValue)) = value
                result += creation(element).update(native: native, oldValue: creation(oldValue))
        }

        if data.count < oldData.count {
            let range = data.count..<oldData.count
            mounts += range.map { native.unmountElement(at: $0) }
        }

        if oldData.count < data.count {
            let range = oldData.count..<data.count
            mounts += range.reduce(into: [Mount]()) { (mounts, index) in
                let component = creation(data[index])
                let (native0, mounts0) = native.reuseElement(component: component) ?? (component.create(prev: nil), [])
                mounts += mounts0
                mounts.append(native.mountElement(element: native0, at: index))
            }
        }
        return mounts
    }

    @inline(__always)
    func enumerate() -> [ComponentBase] {
        data.map(creation).flatMap { $0.asAnyComponent().enumerate() }
    }
}

public extension ForEach where ID == Data.Element {
    @_disfavoredOverload
    init(data: Data, @ComponentBuilder creation: @escaping (Data.Element) -> Component) {
        self.init(data: data, identify: \.self, creation: creation)
    }
}

@available(iOS 13, *)
public extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {
    init(data: Data, @ComponentBuilder creation: @escaping (Data.Element) -> Component) {
        self.init(data: data, identify: \.id, creation: creation)
    }
}
