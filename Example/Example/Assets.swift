//
//  Assets.swift
//  Example
//
//  Created by tarunon on 2020/01/05.
//  Copyright © 2020 tarunon. All rights reserved.
//

import UIKit
import UIViewBuilder

struct Label: UIViewRepresentable, Equatable {
    var text: String
    func create() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textAlignment = .center
        return label
    }

    func update(native: UILabel) {
        native.text = text
    }
}

struct Spacer: UIViewRepresentable, Equatable {
    func create() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 16.0).isActive = true
        return view
    }

    func update(native: UIView) {

    }
}
