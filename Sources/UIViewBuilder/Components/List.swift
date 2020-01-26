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

class NativeTableViewCell<Component: RepresentableBase>: UITableViewCell, MountableRenderer {
    var cache: NativeViewCache {
        (targetParent as! _NativeList).cache
    }
    lazy var natives = createNatives()
    var targetParent: UIViewController?
    var oldContent: AnyComponent?
    var _content: AnyComponent! {
        didSet {
            if oldValue != nil {
                updateContent(oldValue: oldValue)
            }
        }
    }
    var content: AnyComponent {
        get { _content }
        set { _content = newValue }
    }

    var needsToUpdateContent: Bool = false

    var contentViewControllers: [UIViewController] = []
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
                content.willMove(toParent: targetParent)
            } else {
                targetParent?.addChild(content)
            }
        }
    }

    override func didMoveToSuperview() {
        contentViewControllers.forEach { content in
            if superview == nil {
                content.removeFromParent()
            } else {
                content.didMove(toParent: targetParent)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    override func layoutIfNeeded() {
        updateContentIfNeed()
        super.layoutIfNeeded()
    }

    func update(content: Component, parent: _NativeList) {
        self.content = content.asAnyComponent()
        self.targetParent = parent
        _ = natives
        listenProperties()
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
    let cache = NativeViewCache()
    var registedIdentifiers = Set<String>()
}

final class NativeList<Content: ComponentBase>: _NativeList, NativeViewProtocol, ReusableRenderer {
    var components: [RepresentableBase] = []

    func reload(_ f: () -> ()) {
        tableView.reloadData(f)
    }

    func delete(component: RepresentableBase, index: Int) {
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    func insert(component: RepresentableBase, index: Int) {
        type(of: component).registerCellIfNeeded(to: self)
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    func update(component: RepresentableBase, index: Int) {
        type(of: component).registerCellIfNeeded(to: self)
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    var oldContent: Content?

    var content: Content {
        didSet {
            updateContent(oldValue: oldValue)
        }
    }

    var needsToUpdateContent: Bool = false


    init(content: Content) {
        self.content = content
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.beginUpdates()
        update(differences: content.difference(with: nil))
        tableView.endUpdates()
        listenProperties()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContentIfNeed()
    }

    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(viewController: self, at: index, parent: parent)
    }

    func unmount(from target: Mountable) {
        target.unmount(viewController: self)
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

    func update(updation: Update) {
        updation.update(.viewController(self))
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
