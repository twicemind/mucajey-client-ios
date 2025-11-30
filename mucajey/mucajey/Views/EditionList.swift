//
//  EditionList.swift
//  TuneQuest
//
//  Created by Thomas Herfort on 20.11.25.
//

import SwiftUI
import SwiftData

struct EditionList: View {
    @Query private var allEditions: [Edition]
    @Query private var allCards: [Card]
    @State private var expanded: Set<String> = [] // track which editions are expanded

    var body: some View {
        List {
            ForEach(editions, id: \.self) { (edition: String) in
                let cards = filteredCards(selectedEdition: edition)
                if edition != "Alle" {
                    Section {
                        DisclosureGroup(isExpanded: Binding(
                            get: { expanded.contains(edition) },
                            set: { isExp in
                                if isExp { expanded.insert(edition) } else { expanded.remove(edition) }
                            }
                        )) {
                            ForEach(cards, id: \.self) { (card: Card) in
                                CardRowView(card: card, sortOption: .year)
                                    
                                //Text(card.cardId)
                            }
                        } label: {
                            HStack {
                                Text(editionDisplayName(for: edition))
                                Spacer()
                                Text("\(cards.count) cards")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    var editions: [String] {
        let uniqueEditions = Set(allCards.map { $0.edition })
        return ["Alle"] + uniqueEditions.sorted()
    }
    
    func filteredCards(selectedEdition: String) -> [Card] {
        if selectedEdition == "Alle" {
            return allCards
        } else {
            var cards = allCards.filter { $0.edition == selectedEdition }
            cards.sort { $0.cardId < $1.cardId }
            return cards
        }
    }
    
    // Provides a display name for an edition code by resolving against the loaded Edition DTOs.
    // It first tries an exact match on the edition code; if not found, it parses
    // "hitster-%languageShort%-%identifier%" and matches on those fields.
    func editionDisplayName(for editionCode: String) -> String {
        // Try exact match on the Edition model if available
        if let exact = allEditions.first(where: { $0.edition == editionCode }) {
            let name = exact.editionName
            if !name.isEmpty {
                return name
            }
        }

        // Parse schema: hitster-%languageShort%-%identifier% OR hitster-%languageShort%
        let parts = editionCode.split(separator: "-").map(String.init)
        if parts.count >= 2, parts[0] == "hitster" {
            let languageShort = parts[1]
            let identifier = parts.count >= 3 ? parts.dropFirst(2).joined(separator: "-") : nil

            // If identifier exists, try language+identifier match first
            if let identifier, !identifier.isEmpty {
                if let match = allEditions.first(where: { $0.languageShort == languageShort && $0.identifier == identifier }) {
                    let name = match.editionName
                    if !name.isEmpty {
                        return name
                    }
                }
            }

            // Fallback: try to match by language only (for codes like "hitster-de")
            let sameLanguage = allEditions.filter { $0.languageShort == languageShort }
            if !sameLanguage.isEmpty {
                // Prefer an edition with no identifier (base edition)
                if let base = sameLanguage.first(where: { ($0.identifier).isEmpty }) {
                    let name = base.editionName
                    if !name.isEmpty {
                        return name
                    }
                }
                // Otherwise, pick the one with the shortest identifier as a heuristic for base
                if let fallback = sameLanguage.min(by: { ($0.identifier).count < ($1.identifier).count }) {
                    let name = fallback.editionName
                    if !name.isEmpty {
                        return name
                    }
                }
            }
        }

        // Fallback to raw code if nothing found
        return editionCode
    }
}

#Preview {
    EditionList()
}
