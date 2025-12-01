import SwiftUI

struct CardRowView: View {
    let card: Card
    let sortOption: SortOptionFilter
    @State private var isExpanded = false
    @State private var showPlayView = false

    private var badgeTopText: String {
        switch sortOption {
        case .year:   return "Jahr"
        case .cardId: return "ID"
        case .artist: return "Jahr"
        case .title:  return "Jahr"
        case .edition:return "Jahr"
        }
    }

    private var badgeBottomText: String {
        switch sortOption {
        case .year:
            return card.year
        case .cardId:
            return card.cardId
        case .artist, .title, .edition:
            return card.year
        }
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(
            colors: [.pink, .orange, .yellow, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationLink(destination: CardDetailView(card: card)) {
            HStack(spacing: 14) {
                // Gradient-Badge
                VStack(spacing: 2) {
                    Text(badgeTopText.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.85))

                    Text(badgeBottomText)
                        .font(.footnote)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(badgeGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )

                // Titel + Artist
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(card.artist)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer()

                // kleiner Chevron rechts
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
        }
        // der List-Reihe sagen: Hintergrund ist transparent,
        // damit unsere eigene Card zur Geltung kommt
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
