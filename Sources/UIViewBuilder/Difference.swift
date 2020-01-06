//
//  Differenece.swift
//  
//
//  Created by tarunon on 2020/01/05.
//

import Foundation

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

    func with(offset: Int, oldOffset: Int) -> Difference {
        var index = self.index
        switch self.change {
        case .remove:
            index += oldOffset
        case .insert, .update, .stable:
            index += offset
        }
        return Difference(index: index, change: change)
    }
}

extension Collection where Element == Difference {
    func staged() -> (removals: [Difference], insertions: [Difference], updations: [Difference], stables: [Difference]) {
        return reduce(into: (removals: [Difference](), insertions: [Difference](), updations: [Difference](), stables: [Difference]())) { (result, difference) in
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
}
