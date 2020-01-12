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
                    let differences = components.difference(with: oldValue)
                    switch differences.sorted()[0].change {
                    case .stable(let component):
                        XCTAssertTrue(component is ModifiedContent<Label, BackgroundColorModifier>)
                    default:
                        XCTFail("wrong diff: \(differences.sorted()[0])")
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
                    let differences = components.difference(with: oldValue)
                    switch differences.sorted()[0].change {
                    case .update(let component):
                        XCTAssertTrue(component is ModifiedContent<Label, BackgroundColorModifier>)
                    default:
                        XCTFail("wrong diff: \(differences.sorted()[0])")
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
                    let button = (vc._view.stackView.subviews.first as! UIButton)
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
                    let differences = components.difference(with: oldValue)
                    switch differences.sorted()[0].change {
                    case .stable(let component):
                        XCTAssertTrue(component is ModifiedContent<Label, MyModifier>)
                    default:
                        XCTFail("wrong diff: \(differences.sorted()[0])")
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
                        let view = vc._view.stackView.subviews.first
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
