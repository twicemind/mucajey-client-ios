//
//  EditionList.swift
//  TuneQuest
//
//  Created by Thomas Herfort on 20.11.25.
//

import SwiftUI
import SwiftData

struct EditionList: View {
    @Query private var allCards: [HitsterCard]
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
                            ForEach(cards, id: \.self) { (card: HitsterCard) in
                                CardRowView(card: card, sortOption: .year)
                                    
                                //Text(card.cardId)
                            }
                        } label: {
                            HStack {
                                Text(edition)
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
    
    func filteredCards(selectedEdition: String) -> [HitsterCard] {
        if selectedEdition == "Alle" {
            return allCards
        } else {
            var cards = allCards.filter { $0.edition == selectedEdition }
            cards.sort { $0.cardId < $1.cardId }
            return cards
            
        }
    }
}


#Preview {
    EditionList()
}
