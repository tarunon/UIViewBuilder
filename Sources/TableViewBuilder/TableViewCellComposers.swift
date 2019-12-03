//
//  TableViewCellComposers.swift
//  
//
//  Created by tarunon on 2019/12/03.
//

import UIKit

public enum TableViewCell {
    public struct Empty: TableViewCellProtocol {
        public static func register(to tableView: UITableView) {

        }

        public func asTableViewCell() -> UITableViewCell? {
            nil
        }
    }

    public struct Pair<C0, C1>: TableViewCellProtocol where C0: TableViewCellProtocol, C1: TableViewCellProtocol {
        var c0: C0
        var c1: C1

        public static func register(to tableView: UITableView) {
            C0.register(to: tableView)
            C1.register(to: tableView)
        }

        public func asTableViewCell() -> UITableViewCell? {
            c0.asTableViewCell() ?? c1.asTableViewCell()
        }
    }

    public enum Either<C0, C1>: TableViewCellProtocol where C0: TableViewCellProtocol, C1: TableViewCellProtocol {
        case c0(C0)
        case c1(C1)

        public static func register(to tableView: UITableView) {
            C0.register(to: tableView)
            C1.register(to: tableView)
        }

        public func asTableViewCell() -> UITableViewCell? {
            switch self {
            case .c0(let c0): return c0.asTableViewCell()
            case .c1(let c1): return c1.asTableViewCell()
            }
        }
    }
}

extension TableViewCell.Either where C1 == TableViewCell.Empty {
    init(from optional: C0?) {
        if let value = optional {
            self = .c0(value)
        } else {
            self = .c1(.init())
        }
    }
}
