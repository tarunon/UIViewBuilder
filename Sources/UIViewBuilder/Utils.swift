//
//  Utils.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/05.
//

import Foundation

func lazy<T>(type: T.Type = T.self, creation: () -> T) -> T {
    return creation()
}

public typealias PartialApplySelfToIsEqual = (Any?) -> Bool
public protocol MaybeEquatable {
    func partialApplySelfToIsEqual() -> PartialApplySelfToIsEqual
}

extension MaybeEquatable {
    public func partialApplySelfToIsEqual() -> PartialApplySelfToIsEqual {
        { _ in false }
    }
}

extension MaybeEquatable where Self: Equatable {
    public func partialApplySelfToIsEqual() -> PartialApplySelfToIsEqual {
        { self == $0 as? Self }
    }
}

extension MaybeEquatable {
    public func isEqual(to other: Any?) -> Bool {
        self.partialApplySelfToIsEqual()(other)
    }
}
