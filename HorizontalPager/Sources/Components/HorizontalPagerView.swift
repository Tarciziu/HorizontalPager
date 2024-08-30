//
//  HorizontalPagerView.swift
//  HorizontalPager
//
//  Created by Tarciziu Gologan on 29.08.2024.
//

import SwiftUI

/// https://gist.github.com/mecid/e0d4d6652ccc8b5737449a01ee8cbc6f
struct HorizontalPagerView<Item: Hashable & Identifiable, ContentView: View>: View {
  // MARK: - Nested Types

  typealias ContentBuilder = (Item) -> ContentView

  // MARK: - State Properties

  @State private var screenDragDistance: CGFloat = .zero
  @State private var screenHeight: CGFloat = .zero
  @Binding private var selectedItem: Item
  @GestureState private var translation: CGFloat = .zero

  // MARK: - Private Properties

  private let items: [Item]
  private let contentBuilder: ContentBuilder
  private let gesture = DragGesture()
  private var spaceBetweenItems: CGFloat = 10
  private var ratio: CGFloat = 0.8

  // MARK: - Initialization

  init(
    items: [Item],
    selectedItem: Binding<Item>,
    @ViewBuilder contentBuilder: @escaping ContentBuilder
  ) {
    self.items = items
    self._selectedItem = selectedItem
    self.contentBuilder = contentBuilder
  }

  // MARK: - Body

  var body: some View {
    if #available(iOS 17.0, *) {
      scrollingCarousel
    } else {
      itemsCarousel
    }
  }

  // MARK: - Subviews

  @available(iOS 17.0, *)
  private var scrollingCarousel: some View {
    GeometryReader { proxy in
      let itemWidth = calculateItemWidth(availableWidth: proxy.size.width)
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: spaceBetweenItems) {
          ForEach(items) { item in
            contentBuilder(item)
              .frame(width: itemWidth)
              .id(item)
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollIndicators(.hidden)
      .scrollPosition(id: Binding($selectedItem), anchor: .center)
      .animation(.smooth, value: selectedItem)
      .contentMargins(.horizontal, (proxy.size.width - itemWidth) / 2, for: .scrollContent)
    }
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
        .background(
          GeometryReader { proxy in
            Color.clear
              .onAppear {
                screenHeight = proxy.size.height
              }
          }
        )
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
