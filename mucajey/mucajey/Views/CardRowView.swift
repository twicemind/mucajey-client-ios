//
//  CardListRow.swift
//  TuneQuest
//
//  Created by Thomas Herfort on 19.11.25.
//

import SwiftUI

struct CardRowView: View {
    let card: Card
    let sortOption: SortOptionFilter
    @State private var isExpanded = false
    @State private var showPlayView = false
    
    private var badgeTopText: String {
        switch sortOption {
        case .year:
            return "Jahr"
        case .cardId:
            return "ID"
        case .artist:
            return "Jahr"
        case .title:
            return "Jahr"
        case .edition:
            return "Jahr"
        }
    }
    
    private var badgeBottomText: String {
        switch sortOption {
        case .year:
            return card.year
        case .cardId:
            return card.cardId
        case .artist, .title:
            return card.year
        case .edition:
            return card.year
        }
    }
    
    var body: some View {
        NavigationLink(destination: CardDetailView(card: card)) {
            HStack(spacing: 12) {
                // Badge based on sort option
                VStack(spacing: 2) {
                    Text(badgeTopText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.91, green: 0.18, blue: 0.49))
                    
                    Text(badgeBottomText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.91, green: 0.18, blue: 0.49))
                }
                .frame(width: 50)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(card.artist)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
