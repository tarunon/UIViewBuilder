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
