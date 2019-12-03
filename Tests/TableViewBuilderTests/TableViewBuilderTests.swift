import XCTest
import TableViewBuilder
import UIKit

var registeredClassNames = Set<String>()

extension TableViewCellProtocol where Self: UITableViewCell {
    static var className: String {
        "\(type(of: self))"
    }

    static func register(to tableView: UITableView) {
        registeredClassNames.insert(Self.className)
        tableView.register(self, forCellReuseIdentifier: Self.className)
    }

    static func dequeued(tableView: UITableView, indexPath: IndexPath) -> Self {
        tableView.dequeueReusableCell(withIdentifier: Self.className, for: indexPath) as! Self
    }
}

class MyTableViewCell0: UITableViewCell, TableViewCellProtocol {
}

class MyTableViewCell1: UITableViewCell, TableViewCellProtocol {
}

final class TableViewBuilderTests: XCTestCase {
    var tableView: UITableView!

    override func setUp() {
        registeredClassNames = []
        tableView = UITableView()
    }

    func testRegisterCells() {
        let dataSource = tableView.generateDataSource(items: [1, 2, 3]) { (tableView, indexPath, item) in
            if item % 2 == 0 {
                MyTableViewCell0.dequeued(tableView: tableView, indexPath: indexPath)
            } else {
                MyTableViewCell1.dequeued(tableView: tableView, indexPath: indexPath)
            }
        }
        XCTAssertEqual(registeredClassNames, Set([MyTableViewCell0.className, MyTableViewCell1.className]))
    }

    static var allTests = [
        ("testRegisterCells", testRegisterCells)
    ]
}
