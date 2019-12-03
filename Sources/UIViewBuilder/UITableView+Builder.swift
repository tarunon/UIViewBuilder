//
//  UITableView+Builder.swift
//  
//
//  Created by tarunon on 2019/12/03.
//

import UIKit

public class TableViewDataSource<Context: AnyObject, Item>: NSObject, UITableViewDataSource {
    public var items: [Item] {
        didSet {
            reloadData(oldValue, self.items)
        }
    }
    var reloadData: ([Item], [Item]) -> ()
    unowned var context: Context
    var cellForItem: (Context, UITableView, IndexPath, Item) -> UITableViewCell

    init(items: [Item], context: Context, reloadData: @escaping ([Item], [Item]) -> (), cellForItem: @escaping (Context, UITableView, IndexPath, Item) -> UITableViewCell) {
        self.items = items
        self.reloadData = reloadData
        self.context = context
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
        cellForItem(context, tableView, indexPath, items[indexPath.row])
    }
}

class EmptyCell: UITableViewCell {
    override var intrinsicContentSize: CGSize { .zero }
}

public extension UITableView {

    static func defaultReload<Item>(tableView: UITableView, oldItems: [Item], newItems: [Item]) {
        tableView.reloadData()
    }

    func generateDataSource<Item, C: TableViewCellProtocol, Context>(items: [Item], context: Context, reloadData: @escaping (UITableView, [Item], [Item]) -> () = defaultReload, @UIBuilder _ tableViewCells: @escaping (Context, UITableView, IndexPath, Item) -> C) -> TableViewDataSource<Context, Item> {
        defer { self.reloadData() }
        C.register(to: self)
        let dataSource = TableViewDataSource(
            items: items,
            context: context,
            reloadData: { [weak self] oldItems, newItems in
                guard let self = self else { return }
                reloadData(self, oldItems, newItems)
            },
            cellForItem: { context, tableView, indexPath, item in
                return tableViewCells(context, tableView, indexPath, item).asTableViewCell() ?? EmptyCell()
        })
        self.dataSource = dataSource
        return dataSource
    }
}
