//
//  Renderer.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/26.
//

import UIKit

protocol Renderer: class {
    associatedtype Content: _Component
    var oldContent: Content? { get set }
    var content: Content { get set }
    var needsToUpdateContent: Bool { get set }
    func setNeedsLayout()
    func update(differences: Differences)
}

extension Renderer {
    func listenProperties() {
        content.modify.properties.handleUpdate { [weak self] in
            self?.needsToUpdateContent = true
            self?.setNeedsLayout()
        }
    }

    func updateContent(oldValue: Content) {
        if oldContent == nil {
            oldContent = oldValue
            setNeedsLayout()
        }
    }

    func updateContentIfNeed() {
        if needsToUpdateContent || oldContent != nil {
            content.modify.properties.update()
            let oldContent = self.oldContent
            self.oldContent = nil
            needsToUpdateContent = false
            update(differences: content.difference(with: oldContent))
            listenProperties()
        }
    }
}

extension Renderer where Self: UIViewController {
    func setNeedsLayout() {
        view.setNeedsLayout()
    }
}

protocol NativeViewRenderer: Renderer, NativeViewProtocol where Content: RepresentableBase {
    func update()
}

extension NativeViewRenderer {
    func update(differences: Differences) {
        differences.listen { differences in
            if differences.contains(where: { $0.change == .update }) {
                update()
            }
        }
    }
}

protocol MountableRenderer: Renderer, Mountable {
    var cache: NativeViewCache { get }
    var natives: [NativeViewProtocol] { get set }
    var targetParent: UIViewController? { get set }
}

extension MountableRenderer {
    func createNatives() -> [NativeViewProtocol] {
        var natives = [NativeViewProtocol]()
        update(differences: content.difference(with: nil), natives: &natives)
        return natives
    }

    func update(differences: Differences) {
        update(differences: differences, natives: &natives)
    }

    @inline(__always)
    func update(differences: Differences, natives: inout [NativeViewProtocol]) {
        guard let targetParent = targetParent else { return }
        differences.listen { (differences) in
            differences.forEach { difference in
                switch difference.change {
                case .remove:
                    natives[difference.index].unmount(from: self)
                    let native = natives.remove(at: difference.index)
                    cache.enqueue(component: difference.component, native: native)
                case .insert:
                    let native = cache.dequeue(component: difference.component) ?? difference.component.create()
                    native.mount(to: self, at: difference.index, parent: targetParent)
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

extension MountableRenderer where Self: UIViewController {
    var targetParent: UIViewController? {
        get { self }
        set {}
    }
}

extension MountableRenderer where Self: NativeViewProtocol, Self: UIView {
    @inline(__always)
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        self.targetParent = parent
        natives.enumerated().forEach { index, target in
            target.mount(to: self, at: index, parent: parent)
        }
        target.mount(view: self, at: index)
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        natives.reversed().forEach { target in
            target.unmount(from: self)
        }
        target.unmount(view: self)
    }
}

extension MountableRenderer where Self: NativeViewProtocol, Self: UIViewController {
    @inline(__always)
    func mount(to target: Mountable, at index: Int, parent: UIViewController) {
        natives.enumerated().forEach { index, target in
            target.mount(to: self, at: index, parent: parent)
        }
        target.mount(viewController: self, at: index, parent: parent)
    }

    @inline(__always)
    func unmount(from target: Mountable) {
        natives.reversed().forEach { target in
            target.unmount(from: self)
        }
        target.unmount(viewController: self)
    }
}

protocol ReusableRenderer: Renderer {
    var components: [RepresentableBase] { get set }
    func reload(_ f: () -> ())
    func delete(component: RepresentableBase, index: Int)
    func insert(component: RepresentableBase, index: Int)
    func update(component: RepresentableBase, index: Int)
}

extension ReusableRenderer {
    func update(differences: Differences) {
        differences.listen { (differences) in
            reload { [weak self] in
                guard let self = self else { return }
                differences.forEach { difference in
                    switch difference.change {
                    case .remove:
                        self.components.remove(at: difference.index)
                        self.delete(component: difference.component, index: difference.index)
                    case .insert:
                        self.components.insert(difference.component, at: difference.index)
                        self.insert(component: difference.component, index: difference.index)
                    case .update:
                        self.components[difference.index] = difference.component
                        self.update(component: difference.component, index: difference.index)
                    case .stable:
                        break
                    }
                }
            }
        }
    }
}
