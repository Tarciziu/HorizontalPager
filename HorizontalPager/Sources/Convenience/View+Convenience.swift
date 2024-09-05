//
//  View+Convenience.swift
//  HorizontalPager
//
//  Created by Tarciziu Gologan on 05.09.2024.
//

import SwiftUI

extension View {
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { geometryProxy in
        Color.clear
          .preference(key: ContainerSizePreferenceKey.self, value: geometryProxy.size)
      }
    )
    .onPreferenceChange(ContainerSizePreferenceKey.self, perform: onChange)
  }
}

struct ContainerSizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
