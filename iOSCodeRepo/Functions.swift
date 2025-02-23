//
//  Functions.swift
//  SwiftCode
//
//  Created by 丁燕军 on 15/10/14.
//  Copyright © 2015年 DYJ. All rights reserved.
//

import UIKit

extension Array {
  mutating func removeAtIndexes(_ ixs: [Int]) {
    for i in ixs.sorted(by: >) {
      self.remove(at: i)
    }
  }
}

func makeRoundedRectangle(_ sz: CGSize, cornerRadius radius: Float) -> UIImage {
  let image = imageOfSize(sz) { _ in
    let p = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: sz), cornerRadius: CGFloat(radius))
    p.stroke()
  }
  return image
}

func imageOfSize(_ size: CGSize, _ opaque: Bool = false, _ scale: Float = 0, _ whatToDraw: (CGContext) -> ()) -> UIImage {
  UIGraphicsBeginImageContextWithOptions(size, opaque, CGFloat(scale))
  whatToDraw(UIGraphicsGetCurrentContext()!)
  let result = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  return result!
}

func delay(seconds: Double, completion: @escaping () -> ()) {
  let popTime = DispatchTime.now() + seconds
  DispatchQueue.main.asyncAfter(deadline: popTime) {
    completion()
  }
}

/// DEBUG模式下调试输出
func printLog<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
  // 在项目的 Build Settings 中，找到 Swift Compiler - Custom Flags，并在其中的 Other Swift Flags 加上 -D DEBUG
  #if DEBUG
  print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
  #endif
}

extension NSLayoutConstraint {
  class func reportAmbiguity(_ view: UIView?) {
    var v = view
    if v == nil {
      let keyWindow = UIApplication.shared.connectedScenes
        .filter { $0.activationState == .foregroundActive }
        .compactMap { $0 as? UIWindowScene }
        .first?.windows
        .filter { $0.isKeyWindow }.first!
      v = keyWindow
    }
    for vv in v!.subviews {
      print("\(vv) \(vv.hasAmbiguousLayout)")
      if vv.subviews.count > 0 {
        self.reportAmbiguity(vv)
      }
    }
  }

  class func listConstraints(_ view: UIView?) {
    var v = view
    if v == nil {
      let keyWindow = UIApplication.shared.connectedScenes
        .filter { $0.activationState == .foregroundActive }
        .compactMap { $0 as? UIWindowScene }
        .first?.windows
        .filter { $0.isKeyWindow }.first!
      v = keyWindow
    }
    for vv in v!.subviews {
      let arr1 = vv.constraintsAffectingLayout(for: .horizontal)
      let arr2 = vv.constraintsAffectingLayout(for: .vertical)
      NSLog("\n\n%@\nH: %@\nV:%@", vv, arr1, arr2)
      if vv.subviews.count > 0 {
        self.listConstraints(vv)
      }
    }
  }
}
