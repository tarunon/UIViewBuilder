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
        parent.tableView.register(Cell.self, forCellReuseIdentifier: Self.reuseIdentifier)
    }
    
    func dequeueCell(from parent: UITableViewController, indexPath: IndexPath) -> UITableViewCell {
        let cell = parent.tableView.dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath) as! Cell
        cell.render(body: self, parent: parent)
        return cell
    }
}

class NativeCell<Body: ComponentBase>: UITableViewCell, Mountable {
    weak var parentViewController: UIViewController?
    var contentViewControllers: [UIViewController] = []
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

    override func willMove(toSuperview newSuperview: UIView?) {
        contentViewControllers.forEach { content in
            if newSuperview == nil {
                content.willMove(toParent: parentViewController)
            } else {
                parentViewController?.addChild(content)
            }
        }
    }

    override func didMoveToSuperview() {
        contentViewControllers.forEach { content in
            if superview == nil {
                content.removeFromParent()
            } else {
                content.didMove(toParent: parentViewController)
            }
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
            update(differences: body.claim(oldValue: oldComponent), natives: &natives, parent: parent)
        }
    }

    func mount(view: UIView, at index: Int) {
        stackView.insertSubview(view, at: index)
    }

    func mount(viewController: UIViewController, at index: Int, parent: UIViewController) {
        stackView.insertArrangedViewController(viewController, at: index, parentViewController: parent)
        contentViewControllers.append(viewController)
    }

    func unmount(view: UIView) {
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func unmount(viewController: UIViewController) {
        stackView.removeArrangedViewController(viewController)
        contentViewControllers.removeAll(where: { $0 == viewController })
    }
}

class NativeList<Body: ComponentBase>: UITableViewController {
    var body: Body {
        didSet {
            update(differences: body.claim(oldValue: oldValue))
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
        update(differences: body.claim(oldValue: nil))
        tableView.endUpdates()
    }

    func update(differences: [Difference]) {
        differences.forEach { difference in
            switch difference.change {
            case .remove:
                components.remove(at: difference.index)
                tableView.deleteRows(at: [IndexPath(row: difference.index, section: 0)], with: .automatic)
            case .insert(let component):
                component.registerCell(to: self)
                components.insert(component, at: difference.index)
                tableView.insertRows(at: [IndexPath(row: difference.index, section: 0)], with: .automatic)
            case .update(let component):
                component.registerCell(to: self)
                components[difference.index] = component
                tableView.reloadRows(at: [IndexPath(row: difference.index, section: 0)], with: .automatic)
            }
        }
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

    func claim(oldValue: List?) -> [Difference] {
        return [Difference(index: 0, change: .update(self))]
    }

    func update(native: NativeViewProtocol) {
        (native as! NativeList<Body>).body = body
    }
}
