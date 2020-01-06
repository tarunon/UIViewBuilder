//
//  Modified.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/06.
//

private extension ComponentBase {
    func modify<Modifier>(modifier: Modifier) -> ComponentBase {
        return ModifiedContent(content: self, modifier: modifier)
    }
}

extension ComponentBase {
    func modify<Modifier: ComponentModifier>(modifier: Modifier) -> ComponentBase {
        return ModifiedContent(content: self, modifier: modifier)
    }
}

protocol ComponentModifier {
    associatedtype Content: ComponentBase
}

extension ComponentModifier {
    func body(content: Content) -> ModifiedContent<Content, Self> {
        return ModifiedContent(content: content, modifier: self)
    }
}

extension Difference {
    func with<Modifier>(modifier: Modifier, changed: Bool) -> Difference {
        switch self.change {
        case .insert(let component):
            return Difference(index: index, change: .insert(component.modify(modifier: modifier)))
        case .update(let component),
             .stable(let component) where changed:
            return Difference(index: index, change: .update(component.modify(modifier: modifier)))
        case .remove(let component):
            return Difference(index: index, change: .remove(component.modify(modifier: modifier)))
        case .stable(let component):
            return Difference(index: index, change: .stable(component.modify(modifier: modifier)))
        }
    }
}

protocol ModifiedComponent: _Component {
    associatedtype Content: ComponentBase
    associatedtype Modifier

    var content: Content { get }
    var modifier: Modifier { get }
}

extension ModifiedComponent {
    @inline(__always)
    func _create() -> [NativeViewProtocol] {
        content.create()
    }

    @inline(__always)
    func _update(native: NativeViewProtocol) {
        content.update(native: native)
    }

    @inline(__always)
    func _length() -> Int {
        content.length()
    }

    @inline(__always)
    func _difference(with oldValue: Self?) -> [Difference] {
        content.difference(with: oldValue?.content).map {
            $0.with(modifier: modifier, changed: true)
        }
    }
}

extension ModifiedComponent where Modifier: Equatable {
    @inline(__always)
    func _difference(with oldValue: Self?) -> [Difference] {
        content.difference(with: oldValue?.content).map {
            $0.with(modifier: modifier, changed: self.modifier != oldValue?.modifier)
        }
    }
}

public struct ModifiedContent<Content: ComponentBase, Modifier>: ComponentBase, ModifiedComponent {
    public var content: Content
    public var modifier: Modifier

    fileprivate init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
}

extension ModifiedContent where Modifier: ComponentModifier, Modifier.Content == Content {
    init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
}
