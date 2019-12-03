//
//  UITableView+Builder.swift
//  
//
//  Created by tarunon on 2019/12/03.
//

import UIKit

public extension UITableView {
    func generateDataSource<Item, C: TableViewCellProtocol>(items: [Item], @TableViewBuilder _ tableViewCells: @escaping (UITableView, IndexPath, Item) -> C) -> UITableViewDataSource? {
        C.register(to: self)
        return nil
    }
}
