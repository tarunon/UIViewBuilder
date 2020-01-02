//
//  NativeView.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

protocol Mountable {
    func mount(viewController: UIViewController, index: Int, parent: UIViewController)
    func mount(view: UIView, index: Int)
    func unmount(viewController: UIViewController)
    func unmount(view: UIView)
}

protocol NativeViewProtocol: class {
    var prev: NativeViewProtocol? { get set }
    var offset: Int { get }
    var length: Int { get }
    func mount(to target: Mountable, parent: UIViewController)
    func unmount(from target: Mountable)
}

extension NativeViewProtocol {
    @inline(__always)
    var offset: Int {
        prev.map { $0.offset + $0.length } ?? 0
    }
}
