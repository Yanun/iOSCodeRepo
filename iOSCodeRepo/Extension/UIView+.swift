//
//  UIView+.swift
//  iOSCodeRepo
//
//  Created by 丁燕军 on 2023/11/20.
//

import UIKit

extension UIView {
    func findRecursively<T: UIView>(type: T.Type, match: (T) -> Bool) -> T? {
        for view in subviews {
            if let subview = view as? T, match(subview) {
                return subview
            } else {
                return view.findRecursively(type: type, match: match)
            }
        }

        return nil
    }
}
