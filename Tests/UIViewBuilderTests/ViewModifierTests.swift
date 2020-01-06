//
//  ViewModifierTests.swift
//  UIViewBuilderTests
//
//  Created by tarunon on 2020/01/06.
//

import XCTest
@testable import UIViewBuilder

class ViewModifierTests: XCTestCase {
    func testDifferenceChanges() {
        var components = ForEach(data: 0..<3) {
            Label(text: "\($0)")
        }.withEmpty() {
            didSet {
                let differences = components.difference(with: oldValue)
                switch differences[0].change {
                case .stable(let component):
                    XCTAssertTrue(component is ModifiedContent<Label, EmptyModifier<ForEach<Range<Int>, Label, Int>>>)
                default:
                    XCTFail("wrong diff: \(differences[0])")
                }
            }
        }
        components.content.data = 0..<3
    }
}

struct EmptyModifier<Content: ComponentBase>: ComponentModifier, Equatable {
    func modified(content: Content) -> ModifiedContent<Content, EmptyModifier> {
        ModifiedContent(content: content, modifier: self)
    }
}

extension ComponentBase {
    func withEmpty() -> ModifiedContent<Self, EmptyModifier<Self>> {
        EmptyModifier<Self>().modified(content: self)
    }
}
