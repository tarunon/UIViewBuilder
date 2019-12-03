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
