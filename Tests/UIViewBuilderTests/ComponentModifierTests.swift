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

struct BackgroundColorModifier: NativeModifier, Equatable {
    var color: UIColor

    func modify(_ originalUpdate: Update) -> Update {
        Update { native in
            switch native {
            case .view(let view):
                view.backgroundColor = self.color
            case .viewController(let viewController):
                viewController.view.backgroundColor = self.color
            }
            return originalUpdate.update(native)
        }
    }
}

extension ComponentBase {
    func backgroundColor(_ color: UIColor) -> ModifiedContent<Self, BackgroundColorModifier> {
        ModifiedContent<Self, BackgroundColorModifier>(content: self, modifier: BackgroundColorModifier(color: color))
    }
}

struct ForegroundColorModifier: NativeModifier, Equatable {
    var color: UIColor

    func modify(_ originalUpdate: Update) -> Update {
        Update { native in
            switch native {
            case .view(let view):
                view.tintColor = self.color
            case .viewController(let viewController):
                viewController.view.tintColor = self.color
            }
            return originalUpdate.update(native)
        }
    }
}

extension ComponentBase {
    func foregroundColor(_ color: UIColor) -> ModifiedContent<Self, ForegroundColorModifier> {
        ModifiedContent<Self, ForegroundColorModifier>(content: self, modifier: ForegroundColorModifier(color: color))
    }
}
