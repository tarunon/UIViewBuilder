//
//  Mount.swift
//  
//
//  Created by tarunon on 2020/01/05.
//

import Foundation
import UIKit

protocol Mountable: class {
    func mount(viewController: UIViewController, at index: Int, parent: UIViewController)
    func mount(view: UIView, at index: Int)
    func unmount(viewController: UIViewController)
    func unmount(view: UIView)
}

extension Mountable {
    func update(differences: Differences, natives: inout [NativeViewProtocol], cache: NativeViewCache?, parent: UIViewController) {
        differences.sorted().forEach { difference in
            switch difference.change {
            case .remove(let component):
                natives[difference.index].unmount(from: self)
                let native = natives.remove(at: difference.index)
                cache?.enqueue(component: component, native: native)
            case .insert(let component):
                let native = cache?.dequeue(component: component) ?? component.create()[0]
                native.mount(to: self, at: difference.index, parent: parent)
                natives.insert(native, at: difference.index)
            case .update(let component):
                component.update(native: natives[difference.index])
            case .stable:
                break
            }
        }
    }
}
