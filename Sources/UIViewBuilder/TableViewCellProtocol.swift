//
//  TableViewCellProtocol.swift
//
//
//  Created by tarunon on 2019/12/03.
//

import UIKit

public protocol TableViewCellProtocol {
    static func register(to tableView: UITableView)
    func asTableViewCell() -> UITableViewCell?
}

public extension TableViewCellProtocol where Self: UITableViewCell {
    func asTableViewCell() -> UITableViewCell? {
        self
    }
}

extension UISet.Empty: TableViewCellProtocol {
    public static func register(to tableView: UITableView) {

    }

    public func asTableViewCell() -> UITableViewCell? {
        nil
    }
}

extension UISet.Pair: TableViewCellProtocol where C0: TableViewCellProtocol, C1: TableViewCellProtocol {
    public static func register(to tableView: UITableView) {
        C0.register(to: tableView)
        C1.register(to: tableView)
    }

    public func asTableViewCell() -> UITableViewCell? {
        c0.asTableViewCell() ?? c1.asTableViewCell()
    }
}

extension UISet.Either: TableViewCellProtocol where C0: TableViewCellProtocol, C1: TableViewCellProtocol {
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
