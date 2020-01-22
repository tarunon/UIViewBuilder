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
    func update(updation: Update)
}
