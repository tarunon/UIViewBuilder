//
//  Utils.swift
//  UIViewBuilder
//
//  Created by tarunon on 2020/01/05.
//

import Foundation

func lazy<T>(type: T.Type = T.self, creation: () -> T) -> T {
    return creation()
}
