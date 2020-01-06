//
//  Axis.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/06.
//

public enum Axis: Int8, CaseIterable {
    case horizontal
    case vertical

    public struct Set: OptionSet {
        public var rawValue: Int8
        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }

        public static let horizontal = Axis.Set(rawValue: 1 << 0)

        public static let vertical = Axis.Set(rawValue: 1 << 1)
    }
}

import UIKit

extension Axis {
    var nativeLayoutConstraint: NSLayoutConstraint.Axis {
        switch self {
        case .vertical: return .vertical
        case .horizontal: return .horizontal
        }
    }
}
