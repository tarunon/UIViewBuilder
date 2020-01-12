//
//  Differenece.swift
//  
//
//  Created by tarunon on 2020/01/05.
//

import Foundation

class Differences {
    private var _differences: [Difference]

    private init(differences: [Difference]) {
        self._differences = differences
    }

    static var empty: Differences {
        Differences(differences: [])
    }

    static func +(lhs: Differences, rhs: Differences) -> Differences {
        Differences(differences: lhs._differences + rhs._differences)
    }

    static func insertSingle(component: ComponentBase) -> Differences {
        Differences(differences: [Difference(index: 0, change: .insert(component))])
    }

    static func updateSingle(component: ComponentBase) -> Differences {
        Differences(differences: [Difference(index: 0, change: .update(component))])
    }

    static func removeSingle(component: ComponentBase) -> Differences {
        Differences(differences: [Difference(index: 0, change: .remove(component))])
    }

    static func removeRange(range: Range<Int>, component: ComponentBase) -> Differences {
        Differences(differences: range.map { Difference(index: $0, change: .remove(component)) })
    }

    static func stableSingle(component: ComponentBase) -> Differences {
        Differences(differences: [Difference(index: 0, change: .stable(component))])
    }

    func sorted() -> [Difference] {
        _differences.sorted()
    }

    func staged() -> (removals: [Difference], insertions: [Difference], updations: [Difference], stables: [Difference]) {
        return sorted().reduce(into: (removals: [Difference](), insertions: [Difference](), updations: [Difference](), stables: [Difference]())) { (result, difference) in
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

    func with(offset: Int, oldOffset: Int) -> Differences {
        Differences(differences: _differences.map { difference in
            var index = difference.index
            switch difference.change {
            case .remove:
                index += oldOffset
            case .insert, .update, .stable:
                index += offset
            }
            return Difference(index: index, change: difference.change)
        })
    }

    func with<Modifier: ComponentModifier>(modifier: Modifier, changed: Bool) -> Differences {
        Differences(differences: _differences.map { difference in
            switch difference.change {
            case .insert(let component):
                return Difference(index: difference.index, change: .insert(component._modifier(modifier: modifier)))
            case .update(let component),
                 .stable(let component) where changed:
                return Difference(index: difference.index, change: .update(component._modifier(modifier: modifier)))
            case .remove(let component):
                return Difference(index: difference.index, change: .remove(component._modifier(modifier: modifier)))
            case .stable(let component):
                return Difference(index: difference.index, change: .stable(component._modifier(modifier: modifier)))
            }
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
        case insert(ComponentBase)
        case update(ComponentBase)
        case remove(ComponentBase)
        case stable(ComponentBase)
    }
    var index: Int
    var change: Change
}

private extension ComponentBase {
    func _modifier<Modifier: ComponentModifier>(modifier: Modifier) -> ComponentBase {
        return self.modifier(modifier: modifier)
    }
}
