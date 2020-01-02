//
//  NativeView.swift
//  
//
//  Created by tarunon on 2020/01/02.
//

import UIKit

protocol NativeViewProtocol: class {
    var prev: NativeViewProtocol? { get set }
    var offset: Int { get }
    var length: Int { get }
    func mount(to stackView: UIStackView, parent: UIViewController)
    func unmount(from stackView: UIStackView)
}

extension NativeViewProtocol {
    @inline(__always)
    var offset: Int {
        prev.map { $0.offset + $0.length } ?? 0
    }
}
