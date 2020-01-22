//
//  List.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

fileprivate extension RepresentableBase {
    typealias Cell = NativeTableViewCell<Self>
    
    static func registerCellIfNeeded(to parent: _NativeList) {
        if parent.registedIdentifiers.contains(reuseIdentifier) {
            return
        }
        parent.registedIdentifiers.insert(reuseIdentifier)
        parent.tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueCell(from parent: _NativeList, indexPath: IndexPath) -> UITableViewCell {
        let cell = parent.tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! Cell
        cell.update(content: self, parent: parent)
        return cell
    }
}

class NativeTableViewCell<Content: RepresentableBase>: UITableViewCell, Mountable {
    weak var parentViewController: _NativeList!
    var contentViewControllers: [UIViewController] = []
    var component: Content! {
        didSet {
            update(graph: self.component.difference(with: oldValue), natives: &natives, cache: parentViewController!.cache, parent: parentViewController)
        }
    }
    var natives = [NativeViewProtocol]()
    lazy var stackView = lazy(type: UIStackView.self) {
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
    }

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

    func update(content: Content, parent: _NativeList) {
        parentViewController = parent
        component = content
    }

    func mount(view: UIView, at index: Int) {
        stackView.insertArrangedSubview(view, at: index)
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

class _NativeList: UITableViewController {
    var components: [RepresentableBase] = []
    var cache = NativeViewCache()
    var registedIdentifiers = Set<String>()

    func update(difference: Differences) {
        difference.listen { differences in
            tableView.reloadData {
                differences.forEach { difference in
                    switch difference.change {
                    case .remove:
                        components.remove(at: difference.index)
                        tableView.deleteRows(at: [IndexPath(row: difference.index, section: 0)], with: .automatic)
                    case .insert:
                        type(of: difference.component).registerCellIfNeeded(to: self)
                        components.insert(difference.component, at: difference.index)
                        tableView.insertRows(at: [IndexPath(row: difference.index, section: 0)], with: .automatic)
                    case .update:
                        type(of: difference.component).registerCellIfNeeded(to: self)
                        components[difference.index] = difference.component
                        tableView.reloadRows(at: [IndexPath(row: difference.index, section: 0)], with: .automatic)
                    case .stable:
                        break
                    }
                }
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

final class NativeList<Content: ComponentBase>: _NativeList, NativeViewProtocol {
    var content: Content {
        didSet {
            update(difference: content.difference(with: oldValue))
        }
    }

    init(content: Content) {
        self.content = content
        super.init(style: .plain)
        setup(content: content) { self.content.properties.update() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.beginUpdates()
        update(difference: content.difference(with: nil))
        tableView.endUpdates()
    }

    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(viewController: self, at: index, parent: parent)
    }

    func unmount(from target: Mountable) {
        target.unmount(viewController: self)
    }
}

public struct List<Content: ComponentBase>: ComponentBase, NativeRepresentable {
    typealias Native = NativeList<Content>

    public var content: Content

    public init(@ComponentBuilder creation: () -> Content) {
        self.content = creation()
    }

    @inline(__always)
    func create() -> NativeList<Content> {
        .init(content: content)
    }

    @inline(__always)
    func update(native: NativeList<Content>) {
        native.content = content
    }
}

extension UITableView {
    func reloadData(_ f: () -> ()) {
        if #available(iOS 11.0, *) {
            self.performBatchUpdates(f, completion: nil)
        } else {
            beginUpdates()
            f()
            endUpdates()
        }
    }
}
