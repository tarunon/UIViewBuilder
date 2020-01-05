//
//  ScrollViewTests.swift
//  Benchmark
//
//  Created by tarunon on 2020/01/05.
//

import XCTest
import UIKit
import UIViewBuilder


fileprivate extension HostingController {
    func scrollView() -> UIScrollView {
        (view.subviews.first?.subviews.first as! UIScrollView)
    }
}

class ScrollViewTests: XCTestCase {
    func testScrollViewVertical() {
        struct TestComponent: Component {
            var count: Int
            var body: AnyComponent {
                AnyComponent {
                    ScrollView {
                        VStack {
                            ForEach(data: 0..<count) { _ in
                                Block()
                            }
                        }
                    }
                }
            }
        }

        testComponent(
            fixtureType: Int.self,
            creation: {
                TestComponent(count: $0)
            },
            tests: [
                Assert(fixture: 10, assert: { (_, vc) in
                    XCTAssertEqual(vc.scrollView().contentSize.height, 1000)
                }),
                Assert(fixture: 20, assert: { (_, vc) in
                    XCTAssertEqual(vc.scrollView().contentSize.height, 2000)
                })
        ])
    }

    func testScrollViewHorizontal() {
        struct TestComponent: Component {
            var count: Int
            var body: AnyComponent {
                AnyComponent {
                    ScrollView(axes: .horizontal) {
                        HStack {
                            ForEach(data: 0..<count) { _ in
                                Block()
                            }
                        }
                    }
                }
            }
        }

        testComponent(
            fixtureType: Int.self,
            creation: {
                TestComponent(count: $0)
            },
            tests: [
                Assert(fixture: 10, assert: { (_, vc) in
                    XCTAssertEqual(vc.scrollView().contentSize.width, 1000)
                }),
                Assert(fixture: 20, assert: { (_, vc) in
                    XCTAssertEqual(vc.scrollView().contentSize.width, 2000)
                })
        ])
    }

    func testAxisChanges() {
        struct TestComponent: Component {
            var axes: AxisSet
            var body: AnyComponent {
                AnyComponent {
                    ScrollView(axes: axes) {
                        VStack {
                            ForEach(data: 0..<20) { _ in
                                HStack {
                                    ForEach(data: 0..<20) { _ in
                                        Block()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        testComponent(
            fixtureType: AxisSet.self,
            creation: {
                TestComponent(axes: $0)
            },
            tests: [
                Assert(fixture: [], assert: { (_, vc) in
                    XCTAssertNotEqual(vc.scrollView().contentSize.width, 2000)
                    XCTAssertNotEqual(vc.scrollView().contentSize.height, 2000)
                }),
                Assert(fixture: .vertical, assert: { (_, vc) in
                    XCTAssertNotEqual(vc.scrollView().contentSize.width, 2000)
                    XCTAssertEqual(vc.scrollView().contentSize.height, 2000)
                }),
                Assert(fixture: .horizontal, assert: { (_, vc) in
                    XCTAssertEqual(vc.scrollView().contentSize.width, 2000)
                    XCTAssertNotEqual(vc.scrollView().contentSize.height, 2000)
                }),
                Assert(fixture: [.vertical, .horizontal], assert: { (_, vc) in
                    XCTAssertEqual(vc.scrollView().contentSize.width, 2000)
                    XCTAssertEqual(vc.scrollView().contentSize.height, 2000)
                })
        ])
    }
}
