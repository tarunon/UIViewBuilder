//
//  NativeView.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

class NativeViewCache {
    var reuseQueue: [String: [NativeViewProtocol]] = [:]

    func dequeue(component: ComponentBase) -> NativeViewProtocol? {
        guard let native = reuseQueue[component.reuseIdentifier]?.popLast() else {
            return nil
        }
        component.update(native: native)
        return native
    }

    func enqueue(component: ComponentBase, native: NativeViewProtocol) {
        reuseQueue[component.reuseIdentifier, default: []].append(native)
    }
}

protocol NativeViewProtocol: class {
    func mount(to target: Mountable, at index: Int, parent: UIViewController)
    func unmount(from target: Mountable)
}

extension UIView: NativeViewProtocol {
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(view: self, at: index)
    }

    func unmount(from target: Mountable) {
        target.unmount(view: self)
    }
}

extension UIViewController: NativeViewProtocol {
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        target.mount(viewController: self, at: index, parent: parent)
    }

    func unmount(from target: Mountable) {
        target.unmount(viewController: self)
    }
}
