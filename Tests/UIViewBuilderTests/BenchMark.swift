//
//  HStackTests.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import XCTest
import UIKit
@testable import UIViewBuilder

import SwiftUI

class BenchMark: XCTestCase {
    func testBenchmarkComponent() {
        struct Foo: Component {
            var array: [Int]
            var flag: Bool
            var title: String

            var body: AnyComponent {
                AnyComponent {
                    VStack {
                        ForEach(array) {
                            Label(text: "\($0)")
                        }
                        if flag {
                            Button(text: title)
                        } else {
                            TextView(text: title)
                        }
                    }
                }
            }
        }

        let assets = Array(repeating: [
            Foo(array: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], flag: true, title: "abcde"),
            Foo(array: [6, 7, 8, 9, 10], flag: false, title: "edcba")
        ], count: 10000).flatMap { $0 }

        let vc = UIHostingController(Foo(array: [], flag: true, title: ""))

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.isHidden = false

        measure {
            assets.forEach {
                vc.component = $0
            }
        }
    }

    @available(iOS 13, *)
    func testBenchmarkSwiftUI() {
        struct Foo2: View {
            var array: [Int]
            var flag: Bool
            var title: String

            var body: some View {
                SwiftUI.VStack {
                    SwiftUI.ForEach.init(array, id: \.self) {
                        SwiftUI.Text("\($0)")
                    }
                    if flag {
                        SwiftUI.Button(action: { }) {
                            SwiftUI.Text(title)
                        }
                    } else {
                        SwiftUI.Text(title)
                    }
                }
            }
        }

        let assets2 = Array(repeating: [
            Foo2(array: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], flag: true, title: "abcde"),
            Foo2(array: [6, 7, 8, 9, 10], flag: false, title: "edcba")
        ], count: 10000).flatMap { $0 }

        let vc2 = SwiftUI.UIHostingController(rootView: Foo2(array: [], flag: true, title: ""))

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc2
        window.isHidden = false

        measure {
            assets2.forEach {
                vc2.rootView = $0
            }
        }
    }
}
