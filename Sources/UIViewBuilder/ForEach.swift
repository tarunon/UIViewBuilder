//
//  ForEach.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

@available(iOS 13, *)
extension CollectionDifference.Change {
    var offset: Int {
        switch self {
        case .insert(let offset, _, _): return offset
        case .remove(let offset, _, _): return offset
        }
    }
}

public struct ForEach<Data: RandomAccessCollection, Component: ComponentBase, ID: Equatable>: ComponentBase, _Component where Data.Element: Equatable, Data.Index == Int {
    public var data: Data

    var creation: (Data.Element) -> Component
    var identify: KeyPath<Data.Element, ID>

    var body: [Component] {
        data.map(creation)
    }

    public init(data: Data, identify: KeyPath<Data.Element, ID>, @ComponentBuilder creation: @escaping (Data.Element) -> Component) {
        self.data = data
        self.creation = creation
        self.identify = identify
    }

    @inline(__always)
    func create() -> [NativeViewProtocol] {
        body.flatMap { $0.create() }
    }

    struct Reducer {
        var changes: [Change]
        var fixedNewData: [Data.Element]
        var fixedOldData: [Data.Element?]
        var creation: (Data.Element) -> Component

        var fixedNewComponents: [Component] {
            fixedNewData.map(creation)
        }

        var fixedOldComponents: [Component] {
            fixedOldData.compactMap { $0 }.map(creation)
        }
    }

    @inline(__always)
    func traverse(oldValue: ForEach?) -> [Change] {
        guard #available(iOS 13, *) else {
            return updateLegacy(oldValue: oldValue)
        }
        let oldData = oldValue?.data.map { $0 } ?? []

        let diff = data.map { $0[keyPath: identify] }.difference(from: oldData.map { $0[keyPath: identify] })

        let reducer = diff.reduce(into: Reducer(changes: [Change](), fixedNewData: oldData, fixedOldData: oldData, creation: creation)) { (result, change) in
            let viewIndex = result.fixedNewComponents[0..<change.offset].map { $0.length() }.reduce(0, +)
            switch change {
            case .insert(let offset, _, _):
                result.fixedOldData.insert(nil, at: offset)
                result.fixedNewData.insert(data[offset], at: offset)
                result.changes += result.fixedNewComponents[change.offset].traverse(oldValue: nil).map { $0.with(offset: viewIndex) }
            case .remove(let offset, _, _):
                result.changes += (viewIndex..<viewIndex + result.fixedNewComponents[change.offset].length()).reversed().map { Change(index: $0, difference: .remove) }
                result.fixedOldData.remove(at: offset)
                result.fixedNewData.remove(at: offset)
            }
        }

        return reducer.changes + zip(data, reducer.fixedOldData).reduce(into: (viewIndex: 0, changes: [Change]())) { (result, value) in
            let (element, oldValue) = value
            let component = creation(element)
            if let oldValue = oldValue {
                result.changes += component.asAnyComponent().traverse(oldValue: creation(oldValue).asAnyComponent()).map { $0.with(offset: result.viewIndex) }
            }
            result.viewIndex += component.length()
        }.changes
    }


    @inline(__always)
    func updateLegacy(oldValue: ForEach?) -> [Change] {
        fatalError()
    }

    @inline(__always)
    func length() -> Int {
        body.map { $0.length() }.reduce(0, +)
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
