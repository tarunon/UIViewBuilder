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
    func update(graph: Differences, natives: inout [NativeViewProtocol], cache: NativeViewCache?, parent: UIViewController) {
        graph.listen { (differences) in
            differences.forEach { difference in
                switch difference.change {
                case .remove:
                    natives[difference.index].unmount(from: self)
                    let native = natives.remove(at: difference.index)
                    cache?.enqueue(component: difference.component, native: native)
                case .insert:
                    let native = cache?.dequeue(component: difference.component) ?? difference.component.create()
                    native.mount(to: self, at: difference.index, parent: parent)
                    natives.insert(native, at: difference.index)
                case .update:
                    difference.component.update(native: natives[difference.index])
                case .stable:
                    break
                }
            }
        }
    }
}
