//
//  HStackTests.swift
//  
//
//  Created by tarunon on 2019/12/31.
//

import XCTest
import UIKit
import UIViewBuilder
import SwiftUI

class BenchMark: XCTestCase {
    func testBenchmarkComponentStack() {
        struct Foo: Component {
            var array: [Int]
            var flag: Bool
            var title: String

            var body: AnyComponent {
                AnyComponent {
                    VStack {
                        ForEach(data: array) {
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
        ], count: 100).flatMap { $0 }

        let vc = UIHostingController(Foo(array: [], flag: true, title: ""))

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.isHidden = false

        measure {
            assets.forEach {
                vc.component = $0
                vc.view.layoutIfNeeded()
            }
        }
    }

    @available(iOS 13, *)
    func testBenchmarkViewStack() {
        struct Foo: View {
            var array: [Int]
            var flag: Bool
            var title: String

            var body: some View {
                SwiftUI.VStack {
                    SwiftUI.ForEach.init(array, id: \.self) {
                        Text("\($0)")
                    }
                    if flag {
                        SwiftUI.Button(action: { }) {
                            Text(title)
                        }
                    } else {
                        Text(title)
                    }
                }
            }
        }

        let assets = Array(repeating: [
            Foo(array: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], flag: true, title: "abcde"),
            Foo(array: [6, 7, 8, 9, 10], flag: false, title: "edcba")
        ], count: 100).flatMap { $0 }

        let vc = SwiftUI.UIHostingController(rootView: Foo(array: [], flag: true, title: ""))

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.isHidden = false

        measure {
            assets.forEach {
                vc.rootView = $0
                vc.view.layoutIfNeeded()
            }
        }
    }

    func testBenchmarkComponentList() {
         struct Foo: Component {
             var array: [Int]
             var flag: Bool
             var title: String

             var body: AnyComponent {
                 AnyComponent {
                     List {
                         ForEach(data: array) {
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
         ], count: 1).flatMap { $0 }

         let vc = UIHostingController(Foo(array: [], flag: true, title: ""))

         let window = UIWindow(frame: UIScreen.main.bounds)
         window.rootViewController = vc
         window.isHidden = false

         measure {
             assets.forEach {
                 vc.component = $0
                 vc.view.layoutIfNeeded()
             }
         }
     }

     @available(iOS 13, *)
     func testBenchmarkViewList() {
         struct Foo: View {
             var array: [Int]
             var flag: Bool
             var title: String

             var body: some View {
                 SwiftUI.List {
                     SwiftUI.ForEach.init(array, id: \.self) {
                         Text("\($0)")
                     }
                     if flag {
                         SwiftUI.Button(action: { }) {
                             Text(title)
                         }
                     } else {
                         Text(title)
                     }
                 }
             }
         }

         let assets = Array(repeating: [
             Foo(array: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], flag: true, title: "abcde"),
             Foo(array: [6, 7, 8, 9, 10], flag: false, title: "edcba")
         ], count: 1).flatMap { $0 }

         let vc = SwiftUI.UIHostingController(rootView: Foo(array: [], flag: true, title: ""))

         let window = UIWindow(frame: UIScreen.main.bounds)
         window.rootViewController = vc
         window.isHidden = false

         measure {
             assets.forEach {
                 vc.rootView = $0
                 vc.view.layoutIfNeeded()
             }
         }
     }

}
