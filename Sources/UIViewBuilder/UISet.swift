//
//  TableViewCellComposers.swift
//  
//
//  Created by tarunon on 2019/12/03.
//

import UIKit

public enum UISet {
    public struct Empty {}

    public struct Pair<C0, C1> {
        var c0: C0
        var c1: C1
    }

    public enum Either<C0, C1> {
        case c0(C0)
        case c1(C1)
    }
}

extension UISet.Either where C1 == UISet.Empty {
    init(from optional: C0?) {
        if let value = optional {
            self = .c0(value)
        } else {
            self = .c1(.init())
        }
    }
}
