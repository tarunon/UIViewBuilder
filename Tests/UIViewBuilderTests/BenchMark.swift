//
//  HStackTests.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import XCTest
import UIKit
@testable import UIViewBuilder

struct Label: UIViewBuilder.UIViewRepresentable {
    typealias View = UILabel
    var text: String

    func create() -> UILabel {
        let native = UILabel()
        native.translatesAutoresizingMaskIntoConstraints = false
        native.text = text
        return native
    }

    func update(native: UILabel) {
        native.text = text
    }
}

struct TextView: UIViewBuilder.UIViewRepresentable {
    typealias View = UITextView
    var text: String

    func create() -> UITextView {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        return textView
    }

    func update(native: UITextView) {
        native.text = text
    }
}

struct Button: UIViewBuilder.UIViewRepresentable {
    typealias View = UIButton
    var text: String

    func create() -> UIButton {
        let native = UIButton()
        native.translatesAutoresizingMaskIntoConstraints = false
        native.setTitle(text, for: .normal)
        return native
    }

    func update(native: UIButton) {
        native.setTitle(text, for: .normal)
    }
}


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
        ], count: 1000).flatMap { $0 }

        let vc = HostingViewController(Foo(array: [], flag: true, title: ""))

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.isHidden = false

        measure {
            assets.forEach {
                vc.component = $0
                vc.view.setNeedsLayout()
                vc.view.layoutIfNeeded()
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
        ], count: 1000).flatMap { $0 }

        let vc2 = SwiftUI.UIHostingController(rootView: Foo2(array: [], flag: true, title: ""))

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc2
        window.isHidden = false

        measure {
            assets2.forEach {
                vc2.rootView = $0
                // Note: if not layout every time, performance be as x200 time.
                vc2.view.setNeedsLayout()
                vc2.view.layoutIfNeeded()
            }
        }
    }
}
