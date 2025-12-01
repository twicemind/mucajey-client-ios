import SwiftUI
import SwiftData

struct EditionList: View {
    @Query private var allEditions: [Edition]
    @Query private var allCards: [Card]

    @State private var expanded: Set<String> = []      // welche Editions sind aufgeklappt
    @State private var searchText: String = ""         // 🔍 Suchtext

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedMeshGradient()
                .ignoresSafeArea()
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            List {
                ForEach(editions, id: \.self) { edition in
                    if edition != "Alle" {
                        let cardsInEdition = filteredCards(selectedEdition: edition)
                        let cardsToShow = cardsInEdition.filter { matchesSearch($0) }

                        // Edition nur anzeigen, wenn sie zur Suche passt
                        if !cardsToShow.isEmpty {
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expanded.contains(edition) },
                                    set: { isExp in
                                        if isExp {
                                            expanded.insert(edition)
                                        } else {
                                            expanded.remove(edition)
                                        }
                                    }
                                )
                            ) {
                                // Cards innerhalb der Edition
                                VStack(spacing: 8) {
                                    ForEach(cardsToShow, id: \.self) { card in
                                        CardRowView(card: card, sortOption: .year)
                                    }
                                }
                                .padding(.top, 8)
                            } label: {
                                // Kopfzeile pro Edition
                                HStack {
                                    Text(editionDisplayName(for: edition))
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("\(cardsInEdition.count) cards")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                    // ⛔️ Kein eigener Chevron – DisclosureGroup kümmert sich darum
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Color.black.opacity(0.85))
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            // 🔍 Suchfeld im „Standard-SwiftUI-Style“
            .searchable(
                text: $searchText,
                placement: .toolbar, // in einer Tab-App fühlt sich das „standardmäßig“ an
                prompt: "Song, Artist oder Karte suchen"
            )
            // Editions beim Suchen automatisch auf-/zuklappen
            .onChange(of: searchText) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    // Suche leer → alles wieder zu
                    expanded.removeAll()
                } else {
                    // alle Editions aufklappen, die Treffer enthalten
                    let matching = editions.filter { $0 != "Alle" }.filter { edition in
                        let cards = filteredCards(selectedEdition: edition)
                        return cards.contains { matchesSearch($0) }
                    }
                    expanded = Set(matching)
                }
            }
        }
    }

    // MARK: - Helpers

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

    /// Prüft, ob eine Card zum Suchtext passt
    private func matchesSearch(_ card: Card) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return true }

        let needle = query.lowercased()
        return card.title.lowercased().contains(needle)
            || card.artist.lowercased().contains(needle)
            || card.cardId.lowercased().contains(needle)
    }

    func editionDisplayName(for editionCode: String) -> String {
        if let exact = allEditions.first(where: { $0.edition == editionCode }) {
            let name = exact.editionName
            if !name.isEmpty { return name }
        }

        let parts = editionCode.split(separator: "-").map(String.init)
        if parts.count >= 2, parts[0] == "hitster" {
            let languageShort = parts[1]
            let identifier = parts.count >= 3 ? parts.dropFirst(2).joined(separator: "-") : nil

            if let identifier, !identifier.isEmpty {
                if let match = allEditions.first(where: { $0.languageShort == languageShort && $0.identifier == identifier }) {
                    let name = match.editionName
                    if !name.isEmpty { return name }
                }
            }

            let sameLanguage = allEditions.filter { $0.languageShort == languageShort }
            if !sameLanguage.isEmpty {
                if let base = sameLanguage.first(where: { ($0.identifier).isEmpty }) {
                    let name = base.editionName
                    if !name.isEmpty { return name }
                }
                if let fallback = sameLanguage.min(by: { ($0.identifier).count < ($1.identifier).count }) {
                    let name = fallback.editionName
                    if !name.isEmpty { return name }
                }
            }
        }

        return editionCode
    }
}

#Preview {
    NavigationStack {
        EditionList()
            .modelContainer(for: [Edition.self, Card.self])
    }
}
