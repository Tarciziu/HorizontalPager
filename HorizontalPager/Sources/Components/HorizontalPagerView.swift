//
//  HorizontalPagerView.swift
//  HorizontalPager
//
//  Created by Tarciziu Gologan on 29.08.2024.
//

import SwiftUI

private enum Constants {
  static let defaultItemWidthRatio: CGFloat = 0.8
  static let defaultSpacing: CGFloat = 10
}

/// SwiftUI reusable component capable of displaying a list of items while also providing pagination efect.
public struct HorizontalPagerView<Item: Hashable & Identifiable, ContentView: View>: View, Buildable {
  // MARK: - State Properties

  @State private var screenDragDistance: CGFloat = .zero
  @State private var screenHeight: CGFloat = .zero
  @State private var screenWidth: CGFloat = .zero
  @Binding private var selectedItem: Item
  @GestureState private var translation: CGFloat = .zero

  // MARK: - Private Properties

  private let items: [Item]
  private let contentBuilder: (Item) -> ContentView
  private let gesture = DragGesture()
  private var spaceBetweenItems: CGFloat
  private var ratio: CGFloat = Constants.defaultItemWidthRatio

  // MARK: - Initialization
  
  /// Initializes a new `HorizontalPagerView`.
  /// - Parameters:
  ///   - items: A list of ``Hashable`` & ``Identifiable`` items to be displayed.
  ///   - selectedItem: Binding of the selected item from the list.
  ///   - spacing: The distance between adjacent subviews, or `nil` if you
  ///     want the pager to choose a default distance for each pair of
  ///     subviews.
  ///   - contentBuilder: A view builder that creates the content of this pager.
  public init(
    items: [Item],
    selectedItem: Binding<Item>,
    spacing: CGFloat? = nil,
    @ViewBuilder contentBuilder: @escaping (Item) -> ContentView
  ) {
    self.items = items
    self._selectedItem = selectedItem
    self.spaceBetweenItems = spacing ?? Constants.defaultSpacing
    self.contentBuilder = contentBuilder
  }

  // MARK: - Body

  public var body: some View {
    if #available(iOS 17.0, *) {
      scrollingCarousel
    } else {
      itemsCarousel
    }
  }

  // MARK: - Subviews

  @available(iOS 17.0, *)
  @ViewBuilder private var scrollingCarousel: some View {
    let itemWidth = calculateItemWidth(availableWidth: screenWidth)
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: spaceBetweenItems) {
        ForEach(items) { item in
          contentBuilder(item)
            .frame(width: itemWidth)
            .id(item)
        }
      }
      .frame(maxWidth: .infinity)
      .scrollTargetLayout()
    }
    .readSize { size in
      screenWidth = size.width
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
    .scrollPosition(id: Binding($selectedItem), anchor: .center)
    .animation(.smooth, value: selectedItem)
    .contentMargins(.horizontal, (screenWidth - itemWidth) / 2, for: .scrollContent)
  }

  private var itemsCarousel: some View {
    GeometryReader { proxy in
      let itemWidth = calculateItemWidth(availableWidth: proxy.size.width)
      let offset = calculateOffset(availableWidth: proxy.size.width, itemWidth: itemWidth)

      makeItemsList(with: itemWidth, availableWidth: proxy.size.width)
        .offset(x: offset)
        .animation(.default, value: translation)
        .transition(.slide)
        .frame(width: proxy.size.width)
        .gesture(
          gesture
            .updating($translation) { currentState, gestureState, _ in
              gestureState = currentState.translation.width
            }
            .onEnded { value in
              screenDragDistance = .zero
              let index = items.firstIndex { item in
                item.id == selectedItem.id
              } ?? .zero

              if
                value.translation.width < -itemWidth / 4,
                selectedItem != items.last {
                selectedItem = items[items.index(after: index)]
                let impactMediator = UIImpactFeedbackGenerator(style: .medium)
                impactMediator.impactOccurred()
              }

              if
                value.translation.width > itemWidth / 4,
                selectedItem != items.first {
                selectedItem = items[items.index(before: index)]
                let impactMediator = UIImpactFeedbackGenerator(style: .medium)
                impactMediator.impactOccurred()
              }
            }
        )
        .readSize { size in
          screenHeight = size.height
        }
        .frame(maxHeight: screenHeight)
    }
  }

  private func makeItemsList(
    with itemWidth: CGFloat,
    availableWidth: CGFloat
  ) -> some View {
    HStack(alignment: .center, spacing: spaceBetweenItems) {
      ForEach(items) { item in
        contentBuilder(item)
          .frame(width: itemWidth)
      }
    }
  }

  // MARK: - Helper Methods

  private func calculateItemWidth(availableWidth: CGFloat) -> CGFloat {
    availableWidth * ratio
  }

  private func calculateOffset(availableWidth: CGFloat, itemWidth: CGFloat) -> CGFloat {
    guard items.first != items.last else { return  .zero }

    let totalSpacing = (CGFloat(items.count) - 1) * spaceBetweenItems
    let totalCanvasWidth: CGFloat = itemWidth * CGFloat(items.count) + totalSpacing
    let xOffsetToShift = (totalCanvasWidth - availableWidth) / 2
    let widthOfHiddenItem = (availableWidth - itemWidth - spaceBetweenItems * 2) / 2
    let leftPadding = widthOfHiddenItem + spaceBetweenItems
    let totalMovement = itemWidth + spaceBetweenItems

    let index = items.firstIndex { item in
      item.id == selectedItem.id
    } ?? .zero

    let activeOffset = xOffsetToShift + leftPadding - (totalMovement * CGFloat(index))
    let nextOffset = xOffsetToShift + leftPadding - totalMovement * CGFloat(index + 1)

    let resultedOffset = activeOffset != nextOffset
    ? activeOffset + translation
    : activeOffset

    return resultedOffset
  }
}

extension HorizontalPagerView {
  /// Sets width of the item as a percentage (ratio) of the available width.
  /// - Parameter ratio: Ratio out of available width for an item in the list, or `nil` if you want to choose a default width ratio for the items.
  /// - Returns: An updated ``HorizontalPagerView``.
  public func itemWidthRatio(_ ratio: CGFloat) -> Self {
    mutating(keyPath: \.ratio, value: ratio)
  }
}
