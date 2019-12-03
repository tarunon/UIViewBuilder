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
        tableView = UITableView(frame: .init(x: 0, y: 0, width: 320, height: 320))
    }

    func testRegisterCells() {
        _ = tableView.generateDataSource(items: [1, 2, 3], context: self) { (_, tableView, indexPath, item) in
            if item % 2 == 0 {
                MyTableViewCell0.dequeued(tableView: tableView, indexPath: indexPath)
            } else {
                MyTableViewCell1.dequeued(tableView: tableView, indexPath: indexPath)
            }
        }
        XCTAssertEqual(registeredClassNames, Set([MyTableViewCell0.className, MyTableViewCell1.className]))
    }

    func testReuseCells() {
        let dataSource = tableView.generateDataSource(items: [1, 2, 3], context: self) { (_, tableView, indexPath, item) in
            if item % 2 == 0 {
                MyTableViewCell0.dequeued(tableView: tableView, indexPath: indexPath)
            } else {
                MyTableViewCell1.dequeued(tableView: tableView, indexPath: indexPath)
            }
        }

        let cell0a = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell0a is MyTableViewCell1)
        let cell1a = tableView.cellForRow(at: IndexPath(row: 1, section: 0))
        XCTAssertTrue(cell1a is MyTableViewCell0)

        dataSource.items = [0, 1, 2]

        let cell0b = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell0b is MyTableViewCell0)
        let cell1b = tableView.cellForRow(at: IndexPath(row: 1, section: 0))
        XCTAssertTrue(cell1b is MyTableViewCell1)
    }

    static var allTests = [
        ("testRegisterCells", testRegisterCells)
    ]
}
