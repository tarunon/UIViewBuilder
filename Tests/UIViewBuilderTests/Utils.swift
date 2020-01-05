//
//  Utils.swift
//  UIViewBuilderTests
//
//  Created by tarunon on 2020/01/05.
//

import UIViewBuilder
import UIKit

struct Assert<T, Component: ComponentBase> {
    var fixture: T
    var assert: (T, HostingController<Component>) -> ()
}

func testComponent<T, Component: ComponentBase>(fixtureType: T.Type, @ComponentBuilder creation: @escaping (T) -> Component, tests: [Assert<T, Component>]) {
    guard let first = tests.first else {
        return
    }
    let window = UIWindow(frame: UIScreen.main.bounds)
    let vc = HostingController(creation(first.fixture))
    window.rootViewController = vc
    window.isHidden = false
    vc.view.layoutIfNeeded()
    first.assert(first.fixture, vc)

    tests.dropFirst().forEach {
        vc.component = creation($0.fixture)
        vc.view.layoutIfNeeded()
        vc.view.updateConstraintsIfNeeded()

        $0.assert($0.fixture, vc)
    }
}
