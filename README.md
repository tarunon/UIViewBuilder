# UIViewBuilder

Generate UIKit (not SwiftUI) components from FunctionBuilder.
FunctionBuilder is not public feature. 
And this repository is prototyping. Not for production.
Use at your own risk, Extends it with your ideas.

|  | support |
|--|--|
| UITableViewCell | ○ |
| UITableViewHeaderFooterView | wip |
| UICollectionViewCell | wip |
| UICollectionReusableView | wip |
| UIStackView | wip |


## UITableViewCell

We don't need to write `register`, and `dataSource` thing own self.
Writing dequeue cell from item is everything.

```swift
self.dataSource = tableView.generateDataSource(items: [1, 2, 3]) { (tableView, indexPath, item) in
    if item == 0 {
        MyTableViewCell0.dequeued(tableView: tableView, indexPath: indexPath)
    } else if item == 1 {
        MyTableViewCell1.dequeued(tableView: tableView, indexPath: indexPath)
    } else {
        MyTableViewCell2.dequeued(tableView: tableView, indexPath: indexPath)
    }
}
```

It require to extends TableViewCell as 1-liner and typesafe dequeing, we can select favorite method for it.


## Other requirement?

This repository is prototyping. Not for production.
If we hope to use it in product, we'd implement next things.
- Differencable updating.
- Delegate/DataSource proxing.
- HeaderFooter/CollectionView support.

Not required, but we will hope them.
- Declarative style. (not dequeue from list)
- Combine Declarative style and dequeue from list.
