//
//  Graph.swift
//  
//
//  Created by tarunon on 2020/01/05.
//

import Foundation

struct Differences {
    var differences: [Difference]
    private var length: Int
    private var oldLength: Int

    private init(differences: [Difference], length: Int, oldLength: Int) {
        self.differences = differences
        self.length = length
        self.oldLength = oldLength
    }

    private init(differences: [Difference]) {
        self.init(
            differences: differences,
            length: differences.filter { $0.change != .remove }.count,
            oldLength: differences.filter { $0.change != .insert }.count
        )
    }

    static var empty: Differences {
        Differences(differences: [])
    }

    static func insert(component: RepresentableBase) -> Differences {
        Differences(differences: [.init(index: 0, component: component, change: .insert)])
    }

    static func update(component: RepresentableBase) -> Differences {
        Differences(differences: [.init(index: 0, component: component, change: .update)])
    }

    static func remove(component: RepresentableBase) -> Differences {
        Differences(differences: [.init(index: 0, component: component, change: .remove)])
    }

    static func stable(component: RepresentableBase) -> Differences {
        Differences(differences: [.init(index: 0, component: component, change: .stable)])
    }

    static func + (lhs: Differences, rhs: Differences) -> Differences {
        Differences(differences: lhs.differences + rhs.differences.with(offset: lhs.length, oldOffset: lhs.oldLength), length: lhs.length + rhs.length, oldLength: lhs.oldLength + rhs.oldLength)
    }

    func staged() -> (removals: [Difference], insertions: [Difference], updations: [Difference], stables: [Difference]) {
        return differences.sorted().reduce(into: (removals: [Difference](), insertions: [Difference](), updations: [Difference](), stables: [Difference]())) { (result, difference) in
            switch difference.change {
            case .insert:
                result.insertions.append(difference)
            case .update:
                result.updations.append(difference)
            case .remove:
                result.removals.append(difference)
            case .stable:
                result.stables.append(difference)
            }
        }
    }

    func listen(_ handler: ([Difference]) -> ()) {
        let (removals, insertions, updations, _) = staged()
        handler(removals + insertions)
        handler(updations)
    }

    func with<Modifier: ComponentModifier>(modifier: Modifier, changed: Bool) -> Differences {
        Differences(differences: differences.map {
            var difference = $0
            difference.component = difference.component._modifier(modifier: modifier)
            if difference.change == .stable && changed {
                difference.change = .update
            }
            return difference
        })
    }
}

struct Difference: Comparable {
    static func < (lhs: Difference, rhs: Difference) -> Bool {
        switch (lhs.change, rhs.change) {
        case (.remove, .remove): return lhs.index > rhs.index
        case (.remove, _): return true
        case (.insert, .remove): return false
        case (.insert, .insert): return lhs.index < rhs.index
        case (.insert, _): return true
        case (.update, .remove): return false
        case (.update, .insert): return false
        case (.update, .update): return lhs.index < rhs.index
        case (.update, _): return true
        case (.stable, _): return false
        }
    }

    static func == (lhs: Difference, rhs: Difference) -> Bool {
        switch (lhs.change, rhs.change) {
        case (.insert, .insert): return lhs.index == rhs.index
        case (.remove, .remove): return lhs.index == rhs.index
        case (.update, .update): return lhs.index == rhs.index
        case (.stable, .stable): return lhs.index == rhs.index
        default: return false
        }
    }

    enum Change {
        case insert
        case update
        case remove
        case stable
    }
    var index: Int
    var component: RepresentableBase
    var change: Change
}

extension Collection where Element == Difference {
    func with(offset: Int, oldOffset: Int) -> [Difference] {
        map {
            var difference = $0
            switch difference.change {
            case .remove:
                difference.index += oldOffset
            case .insert, .update, .stable:
                difference.index += offset
            }
            return difference
        }
    }
}

private extension ComponentBase {
    func _modifier<Modifier: ComponentModifier>(modifier: Modifier) -> RepresentableBase {
        return self.modifier(modifier: modifier)
    }
}
