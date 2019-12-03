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
    }

    public struct Pair<C0, C1>: TableViewCellProtocol where C0: TableViewCellProtocol, C1: TableViewCellProtocol {
        var c0: C0
        var c1: C1

        public static func register(to tableView: UITableView) {
            C0.register(to: tableView)
            C1.register(to: tableView)
        }
    }

    public enum Either<C0, C1>: TableViewCellProtocol where C0: TableViewCellProtocol, C1: TableViewCellProtocol {
        case c0(C0)
        case c1(C1)

        public static func register(to tableView: UITableView) {
            C0.register(to: tableView)
            C1.register(to: tableView)
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
