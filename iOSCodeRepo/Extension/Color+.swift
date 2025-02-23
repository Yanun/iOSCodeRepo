//
//  Color+.swift
//  iOSCodeRepo
//
//  Created by 丁燕军 on 2022/10/17.
//

import UIKit

extension UIColor {
  
  convenience init(
    light lightModeColor: @escaping @autoclosure () -> UIColor,
    dark darkModeColor: @escaping @autoclosure () -> UIColor
  ) {
    self.init { traitCollection in
      switch traitCollection.userInterfaceStyle {
      case .light, .unspecified:
        return lightModeColor()
      case .dark:
        return darkModeColor()
      @unknown default:
        return lightModeColor()
      }
    }
  }
  
  convenience init(hexString: String) {
    let hex = hexString.trimmingCharacters(in: .alphanumerics.inverted)
    var int: UInt64 = 0
    guard Scanner(string: hex).scanHexInt64(&int) else {
      self.init(red: 0, green: 0, blue: 0, alpha: 1)
      return
    }
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int & 0xFF, int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(red: CGFloat(r) / 255,
              green: CGFloat(g) / 255,
              blue: CGFloat(b) / 255,
              alpha: CGFloat(a) / 255)
  }
}
