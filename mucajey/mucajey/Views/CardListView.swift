//
//  CardView.swift
//  TuneQuest
//
//  Created by Thomas Herfort on 19.11.25.
//

import SwiftUI
import SwiftData

enum SortOptionFilter: String, CaseIterable {
    case year = "Jahr"
    case cardId = "Karten-ID"
    case artist = "Künstler"
    case title = "Titel"
    case edition = "Ausgabe"
    
    var icon: String {
        switch self {
        case .year: return "calendar"
        case .cardId: return "number"
        case .artist: return "person.fill"
        case .title: return "music.note"
        case .edition: return "book"
        }
    }
}

enum StreamingOptionFilter: String, CaseIterable {
    case all = "Alle"
    case appleMusic = "Mit Apple Music"
    case spotify = "Mit Spotify"
    case noStreaming = "Ohne Streaming"
    
    var icon: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .appleMusic: return "applelogo"
        case .spotify: return "music.note"
        case .noStreaming: return "xmark.circle"
        }
    }
}

struct CardListView: View {
    @Query private var allCards: [Card]
    var editionCards: [Card]
    @State private var searchText = ""
    @State private var selectedEdition: String = "Alle"
    @State private var sortOption: SortOptionFilter = .edition
    @State private var streamingOptionFilter: StreamingOptionFilter = .all
    
    var editions: [String] {
        let uniqueEditions = Set(allCards.map { $0.edition })
        return ["Alle"] + uniqueEditions.sorted()
    }
    
    var cardsWithAppleMusic: Int {
        filteredCards.filter { !$0.appleId.isEmpty || !$0.appleUri.isEmpty }.count
    }
    
    var cardsWithSpotify: Int {
        filteredCards.filter { !$0.spotifyId.isEmpty || !$0.spotifyUri.isEmpty }.count
    }
    
    var sortedCards: [Card] {
        var cards = filteredCards
        
        switch sortOption {
        case .year:
            cards.sort { $0.year < $1.year }
        case .cardId:
            cards.sort { $0.id < $1.id }
        case .artist:
            cards.sort { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        case .title:
            cards.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .edition:
            cards.sort { $0.edition.localizedCaseInsensitiveCompare($1.edition) == .orderedAscending }
        }
        
        return cards
    }
    
    var filteredCards: [Card] {
        var filtered = allCards
        
        // Filter nach Edition
        if selectedEdition != "Alle" {
            filtered = filtered.filter { $0.edition == selectedEdition }
        }
        
        // Filter nach Streaming-Service
        switch streamingOptionFilter {
        case .all:
            break
        case .appleMusic:
            filtered = filtered.filter { !$0.appleId.isEmpty || !$0.appleUri.isEmpty }
        case .spotify:
            filtered = filtered.filter { !$0.spotifyId.isEmpty || !$0.spotifyUri.isEmpty }
        case .noStreaming:
            filtered = filtered.filter {
                ($0.appleId.isEmpty && $0.appleUri.isEmpty) &&
                ($0.spotifyId.isEmpty && $0.spotifyUri.isEmpty)
            }
        }
        
        // Filter nach Suchtext
        if !searchText.isEmpty {
            filtered = filtered.filter { card in
                card.title.localizedCaseInsensitiveContains(searchText) ||
                card.artist.localizedCaseInsensitiveContains(searchText) ||
                card.year.contains(searchText) ||
                card.cardId.contains(searchText)
            }
        }
        
        return filtered
    }
    
    var groupedCards: [String: [Card]] {
        switch sortOption {
        case .year:
            return Dictionary(grouping: sortedCards) { $0.year }
        case .cardId:
            return Dictionary(grouping: sortedCards) { String($0.cardId.prefix(2)) + "xxx" }
        case .artist:
            return Dictionary(grouping: sortedCards) {
                String($0.artist.prefix(1).uppercased())
            }
        case .title:
            return Dictionary(grouping: sortedCards) {
                String($0.title.prefix(1).uppercased())
            }
        case .edition:
            return Dictionary(grouping: sortedCards) {
                $0.edition
            }
        }
    }
    
    var sortedGroupKeys: [String] {
        groupedCards.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(sortedGroupKeys, id: \.self) { key in
                        Section {
                            ForEach(groupedCards[key]!, id: \.self) { card in
                                CardListRow(card: card, sortOption: sortOption)
                                /*HStack {
                                 Text(card.title)
                                 .font(.headline)
                                 Spacer()
                                 Text(card.artist)
                                 .font(.subheadline)
                                 }*/
                            }
                        } header: {
                            HStack {
                                Image(systemName: sortOption.icon)
                                    .font(.title3)
                                
                                Text(formatGroupHeader(key))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(groupedCards[key]?.count ?? 0)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Color(red: 0.91, green: 0.18, blue: 0.49).opacity(0.5)
                            )
                        }
                    }
                }
            }
            .background(AnimatedMeshGradient())
            .listStyle(.plain)
            .navigationTitle(Text("Cards"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            
        }
    }
    
    private func formatGroupHeader(_ key: String) -> String {
        switch sortOption {
        case .year:
            return key
        case .cardId:
            return "ID: \(key)"
        case .artist, .title:
            return key
        case .edition:
            return key
        }
    }
}

#Preview {
    @Previewable @Query var cards: [Card]
    
    CardListView(editionCards: cards)
        .modelContainer(for: [Card.self])
}
