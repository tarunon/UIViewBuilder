//
//  UITableView+Builder.swift
//  
//
//  Created by tarunon on 2019/12/03.
//

import UIKit

public class TableViewDataSource<Item>: NSObject, UITableViewDataSource {
    public var items: [Item] {
        didSet {
            reloadData(oldValue, self.items)
        }
    }
    var reloadData: ([Item], [Item]) -> ()
    var cellForItem: (UITableView, IndexPath, Item) -> UITableViewCell

    init(items: [Item], reloadData: @escaping ([Item], [Item]) -> (), cellForItem: @escaping (UITableView, IndexPath, Item) -> UITableViewCell) {
        self.items = items
        self.reloadData = reloadData
        self.cellForItem = cellForItem
        super.init()
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellForItem(tableView, indexPath, items[indexPath.row])
    }
}

public extension UITableView {
    func generateDataSource<Item, C: TableViewCellProtocol>(items: [Item], @TableViewBuilder _ tableViewCells: @escaping (UITableView, IndexPath, Item) -> C) -> TableViewDataSource<Item> {
        defer {
            reloadData()
        }
        C.register(to: self)
        let dataSource = TableViewDataSource(
            items: items,
            reloadData: { [weak self] _, _ in self?.reloadData() },
            cellForItem: { tableView, indexPath, item in
                return tableViewCells(tableView, indexPath, item).asTableViewCell()!
        })
        self.dataSource = dataSource
        return dataSource
    }
}
