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
    var native: NativeViewProtocol!
    weak var parentViewController: UIViewController?
    var contentViewController: UIViewController?
    var oldComponent: Body?
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

    func render(body: Body, parent: UIViewController) {
        if let native = native {
            body.update(native: native, oldValue: oldComponent).forEach { f in
                f(self, parent)
            }
        } else {
            native = body.create(prev: nil)
            native.mount(to: self, parent: parent)
        }
    }

    func mount(view: UIView, index: Int) {
        stackView.insertArrangedSubview(view, at: index)
    }

    func mount(viewController: UIViewController, index: Int, parent: UIViewController) {
        stackView.insertArrangedSubview(viewController.view, at: index)
        parentViewController = parent
    }

    func unmount(view: UIView) {
        stackView.removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func unmount(viewController: UIViewController) {
        stackView.removeArrangedSubview(viewController.view)
        viewController.view.removeFromSuperview()
    }
}

class NativeList<Body: ComponentBase>: UITableViewController, NativeViewProtocol {
    var body: Body

    init(body: Body, prev: NativeViewProtocol?) {
        self.body = body
        self.prev = prev
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var prev: NativeViewProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        body.asAnyComponent().enumerate().forEach { $0.registerCell(to: self) }
        tableView.reloadData()
    }

    @inline(__always)
    var length: Int {
        view.superview == nil ? 0 : 1
    }

    @inline(__always)
    func mount(to target: Mountable, parent: UIViewController) {
        target.mount(viewController: self, index: offset, parent: parent)
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        target.unmount(viewController: self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        body.asAnyComponent().enumerate().count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        body.asAnyComponent().enumerate()[indexPath.row].dequeueCell(from: self, indexPath: indexPath)
    }
}

public struct List<Body: ComponentBase>: ComponentBase, _Component {
    typealias NativeView = NativeList

    var body: Body

    public init(@ComponentBuilder creation: () -> Body) {
        self.body = creation()
    }

    func create(prev: NativeViewProtocol?) -> NativeList<Body> {
        NativeList(body: body, prev: prev)
    }

    func update(native: NativeList<Body>, oldValue: List?) -> [Mount] {
        native.body = body
        native.tableView.reloadData()
        return []
    }

    func enumerate() -> [ComponentBase] {
        return [self]
    }
}
