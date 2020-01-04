//
//  NativeView.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

protocol Mountable {
    func mount(viewController: UIViewController, at index: Int, parent: UIViewController)
    func mount(view: UIView, at index: Int)
    func unmount(viewController: UIViewController?, at index: Int)
    func unmount(view: UIView?, at index: Int)
}

extension Mountable {
    func update(changes: [Change], natives: inout [NativeViewProtocol], parent: UIViewController) {
        changes.forEach { change in
            switch change.difference {
            case .remove:
                natives[change.index].unmount(from: self, at: change.index)
                natives.remove(at: change.index)
            case .insert(let component):
                let native = component.create()[0]
                native.mount(to: self, at: change.index, parent: parent)
                natives.insert(native, at: change.index)
            case .update(let component):
                component.update(native: natives[change.index])
            }
        }
    }
}

protocol NativeViewProtocol: class {
    func mount(to target: Mountable, at index: Int, parent: UIViewController)
    func unmount(from target: Mountable, at index: Int)
}
