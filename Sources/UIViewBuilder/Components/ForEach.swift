//
//  ForEach.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import UIKit

public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Component: ComponentBase>: ComponentBase, NodeComponent where Data.Index == Int {

    public typealias Properties = [ID: Component.Properties]
    public var data: Data {
        didSet {
            properties
                .merge(
                    data.filter { !properties.keys.contains($0[keyPath: identify]) }
                        .map { (key: $0[keyPath: identify], value: creation($0).properties) },
                    uniquingKeysWith: { x, _ in x }
            )
        }
    }
    public var properties: [ID : Component.Properties]

    var content: [Component] {
        data.map(create)
    }

    var creation: (Data.Element) -> Component
    var identify: KeyPath<Data.Element, ID>

    public init(data: Data, identify: KeyPath<Data.Element, ID>, @ComponentBuilder creation: @escaping (Data.Element) -> Component) {
        self.data = data
        self.creation = creation
        self.identify = identify
        self.properties = Dictionary(uniqueKeysWithValues: data.map { (key: $0[keyPath: identify], value: creation($0).properties) })
    }

    private struct Reducer {
        var fixedData: [Data.Element?]
        var fixedOldData: [Data.Element?]
    }

    @inline(__always)
    private func create(_ element: Data.Element) -> Component {
        var component = self.creation(element)
        component.properties = properties[element[keyPath: identify]] ?? component.properties
        return component
    }

    @inline(__always)
    private func difference(reducer: Reducer, oldCreation: (Data.Element) -> Component) -> Differences {
        let content = reducer.fixedData.map { $0.map(create) }
        let oldContent = reducer.fixedOldData.map { $0.map(oldCreation) }

        return zip(content, oldContent).reduce(into: Differences.empty) { (result, value) in
            switch value {
            case (.some(let component), .some(let oldComponent)):
                result = result + component.difference(with: oldComponent)
            case (.some(let component), .none):
                result = result + component.difference(with: nil)
            case (.none, .some(let oldComponent)):
                result = result + oldComponent.destroy()
            case (.none, .none):
                break
            }
        }
    }

    @inline(__always)
    func _difference(with oldValue: ForEach?) -> Differences {
        guard #available(iOS 13, *) else {
            return makeLegacy(with: oldValue)
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

        return difference(reducer: reducer, oldCreation: oldValue?.create ?? { _ in fatalError() })
    }

    @inline(__always)
    func makeLegacy(with oldValue: ForEach?) -> Differences {
        let oldData = oldValue?.data.map { $0 } ?? []
        let reducer: Reducer
        if data.count == oldData.count {
            reducer = Reducer(fixedData: data.map { $0 }, fixedOldData: oldData)
        } else if data.count < oldData.count {
            reducer = Reducer(fixedData: data.map { $0 } + Array(repeating: Data.Element?.none, count: oldData.count - data.count), fixedOldData: oldData)
        } else {
            reducer = Reducer(fixedData: data.map { $0 }, fixedOldData: oldData + Array(repeating: Data.Element?.none, count: data.count - oldData.count))
        }
        return difference(reducer: reducer, oldCreation: oldValue?.create ?? { _ in fatalError() })
    }

    @inline(__always)
    func _destroy() -> Differences {
        content.reduce(into: Differences.empty) {
            $0 = $0 + $1.destroy()
        }
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
