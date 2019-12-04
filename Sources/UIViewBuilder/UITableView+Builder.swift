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

class EmptyCell: UITableViewCell {
    override var intrinsicContentSize: CGSize { .zero }
}

public extension UITableView {

    static func defaultReload<Item>(tableView: UITableView, oldItems: [Item], newItems: [Item]) {
        tableView.reloadData()
    }

    func generateDataSource<Item, C: TableViewCellProtocol>(items: [Item], reloadData: @escaping (UITableView, [Item], [Item]) -> () = defaultReload, @UIBuilder _ tableViewCells: @escaping (UITableView, IndexPath, Item) -> C) -> TableViewDataSource<Item> {
        defer { self.reloadData() }
        C.register(to: self)
        let dataSource = TableViewDataSource(
            items: items,
            reloadData: { [weak self] oldItems, newItems in
                guard let self = self else { return }
                reloadData(self, oldItems, newItems)
            },
            cellForItem: { tableView, indexPath, item in
                return tableViewCells(tableView, indexPath, item).asTableViewCell() ?? EmptyCell()
        })
        self.dataSource = dataSource
        return dataSource
    }
}
