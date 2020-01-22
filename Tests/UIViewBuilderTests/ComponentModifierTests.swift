//
//  ViewModifierTests.swift
//  UIViewBuilderTests
//
//  Created by tarunon on 2020/01/06.
//

import XCTest
@testable import UIViewBuilder

class ComponentModifierTests: XCTestCase {
    func testDifferenceChanges() {
        do {
            var components = ForEach(data: 0..<3) {
                Label(text: "\($0)")
            }.backgroundColor(.red) {
                didSet {
                    let difference = components._difference(with: oldValue).differences[0]
                    switch difference.change {
                    case .stable:
                        XCTAssertTrue(difference.component is _ModifiedContent<Label, BackgroundColorModifier>, "wrong type: \(difference.component)")
                    default:
                        XCTFail("wrong diff: \(difference)")
                    }
                }
            }
            components.content.data = 0..<3
        }
        do {
            var components = ForEach(data: 0..<3) {
                Label(text: "\($0)")
            }.backgroundColor(.red) {
                didSet {
                    let difference = components._difference(with: oldValue).differences[0]
                    switch difference.change {
                    case .update:
                        XCTAssertTrue(difference.component is _ModifiedContent<Label, BackgroundColorModifier>, "wrong type: \(difference.component)")
                    default:
                        XCTFail("wrong diff: \(difference)")
                    }
                }
            }
            components.modifier.color = .black
        }
    }

    func testCreateNativeView() {
        testComponent(
            fixtureType: Void.self,
            creation: { _ in
                Button(text: "test", handler: {

                })
            },
            tests: [
                Assert(fixture: (), assert: { _, vc in
                    let button = (vc.stackView.subviews.first as! UIButton)
                    XCTAssertEqual(button.allTargets.count, 1)
                    XCTAssertEqual(button.allControlEvents, UIControl.Event.touchUpInside)
                })
            ]
        )
    }

    func testMyModifier() {
        struct MyModifier: ComponentModifier, Equatable {
            var backgroundColor: UIColor
            var foregroundColor: UIColor

            func body(content: Content) -> AnyComponent {
                AnyComponent {
                    content
                        .backgroundColor(backgroundColor)
                        .foregroundColor(foregroundColor)
                }
            }
        }

        do {
            var components = ForEach(data: 0..<3) {
                Label(text: "\($0)")
            }.modifier(modifier: MyModifier(backgroundColor: .red, foregroundColor: .yellow)) {
                didSet {
                    let difference = components._difference(with: oldValue).differences[0]
                    switch difference.change {
                    case .stable:
                        XCTAssertTrue(difference.component is _ModifiedContent<Label, MyModifier>, "wrong type: \(difference.component)")
                    default:
                        XCTFail("wrong diff: \(difference)")
                    }
                }
            }
            components.content.data = 0..<3
        }

        do {
            testComponent(
                fixtureType: Void.self,
                creation: { _ in
                    ForEach(data: 0..<3) {
                        Label(text: "\($0)")
                    }.modifier(
                        modifier: MyModifier(
                            backgroundColor: .red,
                            foregroundColor: .yellow
                    ))
                },
                tests: [
                    Assert(fixture: (), assert: { _, vc in
                        let view = vc.stackView.subviews.first
                        XCTAssertEqual(view?.backgroundColor, .red)
                        XCTAssertEqual(view?.tintColor, .yellow)
                    })
                ]
            )
        }
    }
}

struct BackgroundColorModifier: UIViewModifier, Equatable {
    var color: UIColor

    func apply(to view: UIView) {
        view.backgroundColor = color
    }
}

extension ComponentBase {
    func backgroundColor(_ color: UIColor) -> ModifiedContent<Self, BackgroundColorModifier> {
        ModifiedContent<Self, BackgroundColorModifier>(content: self, modifier: BackgroundColorModifier(color: color))
    }
}

struct ForegroundColorModifier: UIViewModifier, Equatable {
    var color: UIColor

    func apply(to view: UIView) {
        view.tintColor = color
    }
}

extension ComponentBase {
    func foregroundColor(_ color: UIColor) -> ModifiedContent<Self, ForegroundColorModifier> {
        ModifiedContent<Self, ForegroundColorModifier>(content: self, modifier: ForegroundColorModifier(color: color))
    }
}
