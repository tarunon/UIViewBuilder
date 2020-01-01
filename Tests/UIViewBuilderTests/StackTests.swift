//
//  StackTests.swift
//  
//
//  Created by tarunon on 2020/01/01.
//

import XCTest
import UIViewBuilder

extension UIHostingController {
    func visibleViews() -> [UIView] {
        (view.subviews.first as! UIStackView).arrangedSubviews.filter { !$0.isHidden }
    }
}

class StackTests: XCTestCase {
    func testPair() {
        struct TestComponent: Component {
            var text0: String
            var text1: String
            var text2: String
            var text3: String
            var text4: String
            var text5: String
            var text6: String
            var text7: String
            var text8: String
            var text9: String

            var body: AnyComponent {
                AnyComponent {
                    VStack {
                        Label(text: text0)
                        Label(text: text1)
                        Label(text: text2)
                        Label(text: text3)
                        Label(text: text4)
                        Label(text: text5)
                        Label(text: text6)
                        Label(text: text7)
                        Label(text: text8)
                        Label(text: text9)
                    }
                }
            }
        }

        var fixture = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

        var component: TestComponent {
            TestComponent(
                text0: fixture[0],
                text1: fixture[1],
                text2: fixture[2],
                text3: fixture[3],
                text4: fixture[4],
                text5: fixture[5],
                text6: fixture[6],
                text7: fixture[7],
                text8: fixture[8],
                text9: fixture[9]
            )
        }

        let vc = UIHostingController(component)

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            fixture
        )

        fixture = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            fixture
        )

        XCTAssertEqual(vc.view.subviews.first?.subviews.count, 10)
    }

    func testEither() {
        struct TestComponent: Component {
            var condition0: Bool
            var condition1: Bool
            var condition2: Bool
            var condition3: Bool
            var condition4: Bool
            var condition5: Bool
            var condition6: Bool
            var condition7: Bool
            var condition8: Bool
            var condition9: Bool

            var body: AnyComponent {
                AnyComponent {
                    VStack {
                        if condition0 {
                            Label(text: "0")
                        }
                        if condition1 {
                            Label(text: "1")
                        }
                        if condition2 {
                            Label(text: "2")
                        }
                        if condition3 {
                            Label(text: "3")
                        }
                        if condition4 {
                            Label(text: "4")
                        }
                        if condition5 {
                            Label(text: "5")
                        } else {
                            Label(text: "a")
                        }
                        if condition6 {
                            Label(text: "6")
                        } else {
                            Label(text: "b")
                        }
                        if condition7 {
                            Label(text: "7")
                        } else {
                            Label(text: "c")
                        }
                        if condition8 {
                            Label(text: "8")
                        } else {
                            Label(text: "d")
                        }
                        if condition9 {
                            Label(text: "9")
                        } else {
                            Label(text: "e")
                        }
                    }
                }
            }
        }

        var fixture = [true, false, true, false, true, false, true, false, true, false]

        var component: TestComponent {
            TestComponent(
                condition0: fixture[0],
                condition1: fixture[1],
                condition2: fixture[2],
                condition3: fixture[3],
                condition4: fixture[4],
                condition5: fixture[5],
                condition6: fixture[6],
                condition7: fixture[7],
                condition8: fixture[8],
                condition9: fixture[9]
            )
        }

        let vc = UIHostingController(component)
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            ["0", "2", "4", "a", "6", "c", "8", "e"]
        )

        fixture = [false, true, false, true, false, true, false, true, false, true]

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            ["1", "3", "5", "b", "7", "d", "9"]
        )

        XCTAssertEqual(vc.view.subviews.first?.subviews.count, 7)
    }

    func testForEach() {
        struct TestComponent: Component {
            var array0: [String]
            var array1: [String]
            var array2: [String]

            var body: AnyComponent {
                AnyComponent {
                    VStack {
                        ForEach(array0) {
                            Label(text: $0)
                        }
                        ForEach(array1) {
                            Label(text: $0)
                        }
                        ForEach(array2) {
                            Label(text: $0)
                        }
                    }
                }
            }
        }

        var fixture = [["1", "2", "3"], ["a", "b", "c"], ["!", "@", "#"]]

        var component: TestComponent {
            TestComponent(
                array0: fixture[0],
                array1: fixture[1],
                array2: fixture[2]
            )
        }

        let vc = UIHostingController(component)
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            fixture.flatMap { $0 }
        )

        fixture = [["1", "2", "3", "4", "5", "6", "7"], ["a", "b", "c"], []]

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            fixture.flatMap { $0 }
        )

        fixture = [[], ["a", "b", "c", "d", "e", "f", "g"], ["!", "@", "#"]]

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            fixture.flatMap { $0 }
        )

        XCTAssertEqual(vc.view.subviews.first?.subviews.count, 10)
    }

    func testNested() {
        struct TestComponent: Component {
            var array0: [String]
            var array1: [String]
            var array2: [String]

            var body: AnyComponent {
                AnyComponent {
                    VStack {
                        HStack {
                            ForEach(array0) {
                                Label(text: $0)
                            }
                        }
                        VStack {
                            ForEach(array1) {
                                Label(text: $0)
                            }
                        }
                        HStack {
                            ForEach(array2) {
                                Label(text: $0)
                            }
                        }
                    }
                }
            }
        }

        var fixture = [["1", "2", "3"], ["a", "b", "c"], ["!", "@", "#"]]

        var component: TestComponent {
            TestComponent(
                array0: fixture[0],
                array1: fixture[1],
                array2: fixture[2]
            )
        }

        let vc = UIHostingController(component)
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { "\(type(of: $0))" },
            ["UIStackView", "UILabel", "UILabel", "UILabel", "UIStackView"]
        )

        fixture = [["1", "2"], [], ["!", "@", "#", "$", "%"]]

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { "\(type(of: $0))" },
            ["UIStackView", "UIStackView"]
        )

        fixture = [[], ["a", "b", "c", "d", "e"], ["!", "@", "#", "$"]]

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { "\(type(of: $0))" },
            ["UIStackView", "UILabel", "UILabel", "UILabel", "UILabel", "UILabel", "UIStackView"]
        )
    }

    func testForEachReuseInEither() {
        struct TestComponent: Component {
            var condition0: Bool
            var array0: [String]

            var body: AnyComponent {
                AnyComponent {
                    VStack {
                        if condition0 {
                            ForEach(array0) {
                                Label(text: $0)
                            }
                        }
                    }
                }
            }
        }

        var fixture = (true, ["1", "2", "3"])

        var component: TestComponent {
            TestComponent(
                condition0: fixture.0,
                array0: fixture.1
            )
        }

        let vc = UIHostingController(component)
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            fixture.1
        )

        fixture = (false, ["1", "2", "3", "4"])

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            []
        )

        fixture = (true, ["1", "2", "3", "4", "5"])

        vc.component = component
        vc.view.layoutIfNeeded()

        XCTAssertEqual(
            vc.visibleViews().map { ($0 as! UILabel).text },
            fixture.1
        )
    }
}

