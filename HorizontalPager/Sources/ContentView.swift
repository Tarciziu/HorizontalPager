//
//  ContentView.swift
//  HorizontalPager
//
//  Created by Tarciziu Gologan on 29.08.2024.
//

import SwiftUI

struct ContentView: View {
  let items = [
    Card(id: "1", name: "1"),
    Card(id: "2", name: "2"),
    Card(id: "3", name: "3"),
    Card(id: "4", name: "4")
  ]

  @State private var selectedCard = Card(id: "1", name: "1")
  @State private var text = String()

  // MARK: - Body

  var body: some View {
    VStack(spacing: .zero) {
      Spacer()
      carousel
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Subviews

  private var carousel: some View {
    HorizontalPagerView(
      items: items,
      selectedItem: $selectedCard,
      spacing: 20,
      itemWidthRatio: 0.7
    ) { item in
      Text(item.name)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.red)
        .scaleEffect(y: selectedCard.id == item.id ? 1.0 : 0.8)
        .cornerRadius(12)
    }
  }
}

struct Card: Identifiable, Hashable {
  let id: String
  let name: String
}

#Preview {
  ContentView()
}
