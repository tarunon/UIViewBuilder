//
//  TableViewBuilder.swift
//  
//
//  Created by tarunon on 2019/12/03.
//

@_functionBuilder
public struct ComponentBuilder {
    public typealias Empty = ComponentSet.Empty
    public typealias Pair = ComponentSet.Pair
    public typealias Either = ComponentSet.Either

    public static func buildBlock() -> Empty {
        .init()
    }

    public static func buildBlock<C>(_ c: C) -> C {
        c
    }

    public static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> Pair<C0, C1> {
        .init(c0: c0, c1: c1)
    }

    public static func buildIf<C>(_ c: C?) -> Either<C, Empty> {
        .init(from: c)
    }

    public static func buildEither<T, F>(first: T) -> Either<T, F> {
        .c0(first)
    }

    public static func buildEither<T, F>(second: F) -> Either<T, F> {
        .c1(second)
    }
}

public extension ComponentBuilder {
    static func buildBlock<C0, C1, C2>(_ c0: C0, _ c1: C1, _ c2: C2) -> Pair<Pair<C0, C1>, C2> {
        .init(c0: .init(c0: c0, c1: c1), c1: c2)
    }

    static func buildBlock<C0, C1, C2, C3>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> Pair<Pair<C0, C1>, Pair<C2, C3>> {
        .init(c0: .init(c0: c0, c1: c1), c1: .init(c0: c2, c1: c3))
    }

    static func buildBlock<C0, C1, C2, C3, C4>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> Pair<Pair<Pair<C0, C1>, Pair<C2, C3>>, C4> {
        .init(c0: .init(c0: .init(c0: c0, c1: c1), c1: .init(c0: c2, c1: c3)), c1: c4)
    }

    static func buildBlock<C0, C1, C2, C3, C4, C5>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) -> Pair<Pair<Pair<C0, C1>, Pair<C2, C3>>, Pair<C4, C5>> {
        .init(c0: .init(c0: .init(c0: c0, c1: c1), c1: .init(c0: c2, c1: c3)), c1: .init(c0: c4, c1: c5))
    }

    static func buildBlock<C0, C1, C2, C3, C4, C5, C6>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) -> Pair<Pair<Pair<C0, C1>, Pair<C2, C3>>, Pair<Pair<C4, C5>, C6>> {
        .init(c0: .init(c0: .init(c0: c0, c1: c1), c1: .init(c0: c2, c1: c3)), c1: .init(c0: .init(c0: c4, c1: c5), c1: c6))
    }

    static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) -> Pair<Pair<Pair<C0, C1>, Pair<C2, C3>>, Pair<Pair<C4, C5>, Pair<C6, C7>>> {
        .init(c0: .init(c0: .init(c0: c0, c1: c1), c1: .init(c0: c2, c1: c3)), c1: .init(c0: .init(c0: c4, c1: c5), c1: .init(c0: c6, c1: c7)))
    }

    static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) -> Pair<Pair<Pair<Pair<C0, C1>, Pair<C2, C3>>, Pair<Pair<C4, C5>, Pair<C6, C7>>>, C8> {
        .init(c0: .init(c0: .init(c0: .init(c0: c0, c1: c1), c1: .init(c0: c2, c1: c3)), c1: .init(c0: .init(c0: c4, c1: c5), c1: .init(c0: c6, c1: c7))), c1: c8)
    }

    static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) -> Pair<Pair<Pair<Pair<C0, C1>, Pair<C2, C3>>, Pair<Pair<C4, C5>, Pair<C6, C7>>>, Pair<C8, C9>> {
        .init(c0: .init(c0: .init(c0: .init(c0: c0, c1: c1), c1: .init(c0: c2, c1: c3)), c1: .init(c0: .init(c0: c4, c1: c5), c1: .init(c0: c6, c1: c7))), c1: .init(c0: c8, c1: c9))
    }
}
