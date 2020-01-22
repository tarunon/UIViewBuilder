//
//  NativeView.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

class NativeViewCache {
    var reuseQueue: [String: [NativeViewProtocol]] = [:]

    func dequeue(component: RepresentableBase) -> NativeViewProtocol? {
        guard let native = reuseQueue[component.reuseIdentifier]?.popLast() else {
            return nil
        }
        component.update(native: native)
        return native
    }

    func enqueue(component: RepresentableBase, native: NativeViewProtocol) {
        reuseQueue[component.reuseIdentifier, default: []].append(native)
    }
}

protocol NativeViewProtocol: class {
    func mount(to target: Mountable, at index: Int, parent: UIViewController)
    func unmount(from target: Mountable)
}

extension NativeViewProtocol {
    func setup<Content: ComponentBase>(content: Content, update: @escaping () -> ()) {
        content.properties.handleUpdate(update)
    }
}

class NativeViewWrapper<View: UIView, Content: ComponentBase & RepresentableBase>: NativeViewProtocol {
    let view: View
    var content: Content {
        didSet {
            content.update(native: self)
        }
    }

    init(view: View, content: Content) {
        self.view = view
        self.content = content
        setup(content: content) { self.content.properties.update() }
    }

    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(view: view, at: index)
    }

    func unmount(from target: Mountable) {
        target.unmount(view: view)
    }
}

class NativeViewControllerWrapper<ViewController: UIViewController, Content: ComponentBase & RepresentableBase>: NativeViewProtocol {
    var needsToUpdateContent: Bool = false
    let viewController: ViewController
    var content: Content {
        didSet {
            content.update(native: self)
        }
    }

    init(viewController: ViewController, content: Content) {
        self.viewController = viewController
        self.content = content
        setup(content: content) { self.content.properties.update() }
    }

    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(viewController: viewController, at: index, parent: parent)
    }

    func unmount(from target: Mountable) {
        target.unmount(viewController: viewController)
    }
}
