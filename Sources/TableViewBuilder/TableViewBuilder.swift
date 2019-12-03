//
//  TableViewBuilder.swift
//  
//
//  Created by tarunon on 2019/12/03.
//

import UIKit

@_functionBuilder
public struct TableViewBuilder {
    public static func buildBlock() -> TableViewCell.Empty {
        .init()
    }

    public static func buildBlock<C: TableViewCellProtocol>(_ c: C) -> C {
        c
    }

    public static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TableViewCell.Pair<C0, C1> {
        .init(c0: c0, c1: c1)
    }

    public static func buildIf<C>(_ c: C?) -> TableViewCell.Either<C, TableViewCell.Empty> {
        .init(from: c)
    }

    public static func buildEither<T, F>(first: T) -> TableViewCell.Either<T, F> {
        .c0(first)
    }

    public static func buildEither<T, F>(second: F) -> TableViewCell.Either<T, F> {
        .c1(second)
    }
}
