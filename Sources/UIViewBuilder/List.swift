//
//  List.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

fileprivate extension ComponentBase {
    typealias Cell = NativeCell<Self>

    func registerCell(to parent: UITableViewController) {
        parent.tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
    }
    
    func dequeueCell(from parent: UITableViewController, indexPath: IndexPath) -> UITableViewCell {
        let cell = parent.tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
        cell.render(body: self, parent: parent)
        return cell
    }
}

class NativeCell<Body: ComponentBase>: UITableViewCell, Mountable {
    weak var parentViewController: UIViewController?
    var contentViewController: UIViewController?
    var oldComponent: Body?
    var natives: [NativeViewProtocol]!
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate(
            [
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
                stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
                stackView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
            ] + [
                stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ].map { $0.priority = UILayoutPriority.defaultHigh; return $0 }
        )
        return stackView
    }()

    static var reuseIdentifier: String {
        "\(ObjectIdentifier(Body.self).hashValue)"
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        guard let contentViewController = contentViewController else { return }
        if newSuperview == nil {
            contentViewController.willMove(toParent: parentViewController)
        } else {
            parentViewController?.addChild(contentViewController)
        }
    }

    override func didMoveToSuperview() {
        guard let contentViewController = contentViewController else { return }
        if superview == nil {
            contentViewController.removeFromParent()
        } else {
            contentViewController.didMove(toParent: parentViewController)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func render(body: Body, parent: UIViewController) {
        if natives == nil {
            natives = body.create()
            natives.enumerated().forEach { index, native in
                native.mount(to: self, at: index, parent: parent)
            }
        } else {
            update(changes: body.traverse(oldValue: oldComponent), natives: &natives, parent: parent)
        }
    }

    func mount(view: UIView, at index: Int) {
        stackView.insertSubview(view, at: index)
    }

    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        stackView.insertArrangedViewController(viewController, at: index, parentViewController: parent)
        contentViewController = viewController
    }

    func unmount(view: UIView?, at index: Int) {
        view.map(stackView.removeArrangedSubview)
        view?.removeFromSuperview()
    }

    func unmount(viewController: UIViewController?, at index: Int) {
        viewController?.view.map(stackView.removeArrangedSubview(_:))
        viewController?.view.removeFromSuperview()
    }
}

class NativeList<Body: ComponentBase>: UITableViewController, NativeViewProtocol {
    var body: Body {
        didSet {
            update(changes: body.traverse(oldValue: oldValue))
        }
    }

    var components: [ComponentBase] = []

    init(body: Body) {
        self.body = body
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var prev: NativeViewProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.beginUpdates()
        update(changes: body.traverse(oldValue: nil))
        tableView.endUpdates()
    }

    func update(changes: [Change]) {
        changes.forEach { change in
            switch change.difference {
            case .remove:
                components.remove(at: change.index)
                tableView.deleteRows(at: [IndexPath(row: change.index, section: 0)], with: .automatic)
            case .insert(let component):
                component.registerCell(to: self)
                components.insert(component, at: change.index)
                tableView.insertRows(at: [IndexPath(row: change.index, section: 0)], with: .automatic)
            case .update(let component):
                component.registerCell(to: self)
                components[change.index] = component
                tableView.reloadRows(at: [IndexPath(row: change.index, section: 0)], with: .automatic)
            }
        }
    }

    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(viewController: self, at: index, parent: parent)
    }

    func unmount(from target: Mountable, at index: Int) {
        target.unmount(viewController: self, at: index)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        components.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        components[indexPath.row].dequeueCell(from: self, indexPath: indexPath)
    }
}

public struct List<Body: ComponentBase>: ComponentBase, _Component {
    var body: Body

    public init(@ComponentBuilder creation: () -> Body) {
        self.body = creation()
    }

    func create() -> [NativeViewProtocol] {
        [NativeList(body: body)]
    }

    func traverse(oldValue: List?) -> [Change] {
        return [Change(index: 0, difference: .update(self))]
    }

    func update(native: NativeViewProtocol) {
        (native as! NativeList<Body>).body = body
    }
}
