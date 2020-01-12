//
//  ForEach.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public struct ForEach<Data: RandomAccessCollection, ID: Equatable, Component: ComponentBase>: ComponentBase, _Component where Data.Index == Int {
    public var data: Data

    var creation: (Data.Element) -> Component
    var identify: KeyPath<Data.Element, ID>

    var content: [Component] {
        data.map(creation)
    }

    public init(data: Data, identify: KeyPath<Data.Element, ID>, @ComponentBuilder creation: @escaping (Data.Element) -> Component) {
        self.data = data
        self.creation = creation
        self.identify = identify
    }

    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        content.flatMap { $0.create() }
    }

    private struct Reducer {
        var fixedData: [Data.Element?]
        var fixedOldData: [Data.Element?]
    }

    @inline(__always)
    private func difference(reducer: Reducer, oldCreation: (Data.Element) -> Component) -> Differences {
        let content = reducer.fixedData.map { $0.map(creation) }
        let oldContent = reducer.fixedOldData.map { $0.map(oldCreation) }

        return zip(content, oldContent).reduce(into: (viewIndex: 0, oldViewIndex: 0, differences: Differences.empty)) { (result, value) in
            switch value {
            case (.some(let component), .some(let oldComponent)):
                result.differences = result.differences + component.difference(with: oldComponent).with(offset: result.viewIndex, oldOffset: result.oldViewIndex)
                result.viewIndex += component.length()
                result.oldViewIndex += oldComponent.length()
            case (.some(let component), .none):
                result.differences = result.differences + component.difference(with: nil).with(offset: result.viewIndex, oldOffset: result.oldViewIndex)
                result.viewIndex += component.length()
            case (.none, .some(let oldComponent)):
                let length = oldComponent.length()
                result.differences = result.differences + Differences.removeRange(range: result.oldViewIndex..<result.oldViewIndex + length, component: oldComponent)
                result.oldViewIndex += length
            case (.none, .none):
                break
            }
        }.differences
    }

    @inline(__always)
    func _difference(with oldValue: ForEach?) -> Differences {
        guard #available(iOS 13, *) else {
            return differenceLegacy(with: oldValue)
        }
        let oldData = oldValue?.data.map { $0 } ?? []
        let diff = data.map { $0[keyPath: identify] }.difference(from: oldData.map { $0[keyPath: identify] })

        var reducer = diff.removals.reversed().reduce(into: Reducer(fixedData: data.reversed(), fixedOldData: oldData)) { (result, difference) in
           switch difference {
           case .insert:
               break
           case .remove(let offset, _, _):
               result.fixedData.insert(nil, at: result.fixedOldData.count - offset - 1)
           }
        }

        reducer = diff.insertions.reduce(into: reducer) { (result, difference) in
            switch difference {
            case .insert(let offset, _, _):
                result.fixedOldData.insert(nil, at: offset)
            case .remove:
                break
            }
        }

        reducer.fixedData = reducer.fixedData.reversed()

        return difference(reducer: reducer, oldCreation: oldValue?.creation ?? { _ in fatalError() })
    }

    @inline(__always)
    func differenceLegacy(with oldValue: ForEach?) -> Differences {
        let oldData = oldValue?.data.map { $0 } ?? []
        let reducer: Reducer
        if data.count == oldData.count {
            reducer = Reducer(fixedData: data.map { $0 }, fixedOldData: oldData)
        } else if data.count < oldData.count {
            reducer = Reducer(fixedData: data.map { $0 } + Array(repeating: Data.Element?.none, count: oldData.count - data.count), fixedOldData: oldData)
        } else {
            reducer = Reducer(fixedData: data.map { $0 }, fixedOldData: oldData + Array(repeating: Data.Element?.none, count: data.count - oldData.count))
        }
        return difference(reducer: reducer, oldCreation: oldValue?.creation ?? { _ in fatalError() })
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        fatalError()
    }

    @inline(__always)
    func _length() -> Int {
        content.map { $0.length() }.reduce(0, +)
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
