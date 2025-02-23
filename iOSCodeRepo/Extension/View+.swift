//
//  View.swift
//  Test
//
//  Created by xndm on 2025/1/21.
//

import Foundation
import SwiftUI

extension View {
  func onNotification(
    _ notificationName: Notification.Name,
    perform action: @escaping () -> Void
  ) -> some View {
    onReceive(NotificationCenter.default.publisher(
      for: notificationName
    )) { _ in
      action()
    }
  }

  func onAppEnteredBackground(
    perform action: @escaping () -> Void
  ) -> some View {
    onNotification(
      UIApplication.didEnterBackgroundNotification,
      perform: action
    )
  }
}

private struct SizePreferenceKey: PreferenceKey {
  static let defaultValue = CGSize.zero

  static func reduce(value: inout CGSize,
                     nextValue: () -> CGSize)
  {
    value = nextValue()
  }
}

extension View {
  func syncingSize(to binding: Binding<CGSize?>) -> some View {
    background(GeometryReader { proxy in
      Color.clear.preference(
        key: SizePreferenceKey.self,
        value: proxy.size
      )
    })
    .onPreferenceChange(SizePreferenceKey.self) {
      binding.wrappedValue = $0
    }
  }
}

struct TilingModifier: ViewModifier {
  var image: Image
  var capInsets: EdgeInsets

  @State private var imageSize: CGSize?
  @State private var viewSize: CGSize?

  func body(content: Content) -> some View {
    // Adjusting the size of our view to fit the tiling of
    // our background image:
    content.frame(
      minWidth: sizeComponent(\.width,
                              insetBy: (capInsets.leading, capInsets.trailing)),
      minHeight: sizeComponent(\.height,
                               insetBy: (capInsets.top, capInsets.bottom))
    )
    // Rendering our background, just like we did before:
    .background(image.resizable(
      capInsets: capInsets,
      resizingMode: .tile
    ))
    // Syncing our view's size, and the size of our image,
    // by rendering a hidden, non-tiled version of it within
    // our view hierarchy:
    .syncingSize(to: $viewSize)
    .background(image.hidden().syncingSize(to: $imageSize))
  }
}

private extension TilingModifier {
  func sizeComponent(
    _ component: KeyPath<CGSize, CGFloat>,
    insetBy insets: (CGFloat, CGFloat)
  ) -> CGFloat? {
    // If we haven't yet captured our view and image sizes,
    // we'll simply return nil until that info is available:
    guard let viewSize = viewSize,
          let imageSize = imageSize
    else {
      return nil
    }

    // Computing the length of the tiling parts of both our
    // image and our view, by subtracting the insets from
    // their total lengths:
    let tiling: (CGFloat) -> CGFloat = {
      $0 - insets.0 - insets.1
    }

    let viewMetric = tiling(viewSize[keyPath: component])
    let imageMetric = tiling(imageSize[keyPath: component])

    // The final view length should be equal to the total
    // length of our tiles plus our insets:
    let tileCount = ceil(viewMetric / imageMetric)
    return insets.0 + tileCount * imageMetric + insets.1
  }
}

extension View {
  func tiledBackground(with image: Image,
                       capInsets: EdgeInsets) -> some View
  {
    modifier(TilingModifier(
      image: image,
      capInsets: capInsets
    ))
  }
}

extension Shape {
  func style<S: ShapeStyle, F: ShapeStyle>(
    withStroke strokeContent: S,
    lineWidth: CGFloat = 1,
    fill fillContent: F
  ) -> some View {
    stroke(strokeContent, lineWidth: lineWidth)
      .background(fill(fillContent))
  }
}
