import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable {
    case year = "Jahr"
    case cardId = "Karten-ID"
    case artist = "Künstler"
    case title = "Titel"
    
    var icon: String {
        switch self {
        case .year: return "calendar"
        case .cardId: return "number"
        case .artist: return "person.fill"
        case .title: return "music.note"
        }
    }
}

enum StreamingFilter: String, CaseIterable {
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

struct DataOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [HitsterCard]
    @Query private var syncStatus: [SyncStatus]
    
    @State private var searchText = ""
    @State private var selectedEdition: String = "Alle"
    @State private var sortOption: SortOption = .year
    @State private var streamingFilter: StreamingFilter = .all
    @State private var showFilterSheet = false
    @State private var showSortMenu = false
    
    
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
    
    var sortedCards: [HitsterCard] {
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
        }
        
        return cards
    }
    
    var filteredCards: [HitsterCard] {
        var filtered = allCards
        
        // Filter nach Edition
        if selectedEdition != "Alle" {
            filtered = filtered.filter { $0.edition == selectedEdition }
        }
        
        // Filter nach Streaming-Service
        switch streamingFilter {
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
    
    var groupedCards: [String: [HitsterCard]] {
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
        }
    }
    
    var sortedGroupKeys: [String] {
        groupedCards.keys.sorted()
    }
    
    var body: some View {
        
        NavigationStack{ //NavigationStack
            ZStack{
                Spacer()
                contentView
            }
            .padding(.top, 20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) { Label("start.instructions", systemImage: "checkmark")}
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(
                selectedEdition: $selectedEdition,
                streamingFilter: $streamingFilter,
                sortOption: $sortOption,
                editions: editions
            )
        }
        
    }
    
    @ViewBuilder
    private var contentView: some View {
        Group {
            VStack(spacing: 12) {
                if filteredCards.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.purple.opacity(0.5))
                        
                        Text(LocalizedStringKey("message.noData"))
                            .font(.headline)
                            .foregroundColor(.purple.opacity(0.7))
                    }
                    Spacer()
                } else {
                    HStack(spacing: 12) {
                        InfoCard(
                            icon: "music.note.list",
                            title: "Karten gesamt",
                            value: "\(allCards.count)"
                        )
                        
                        InfoCard(
                            icon: "line.3.horizontal.decrease.circle",
                            title: "Gefiltert",
                            value: "\(filteredCards.count)"
                        )
                        
                        InfoCard(
                            icon: "square.stack.3d.up",
                            title: "Editionen",
                            value: "\(editions.count - 1)"
                        )
                    }
                    HStack(spacing: 12) {
                        InfoCard(
                            icon: "applelogo",
                            title: "Apple Music",
                            value: "\(cardsWithAppleMusic)",
                            subtitle: "\(Int((Double(cardsWithAppleMusic) / Double(max(filteredCards.count, 1))) * 100))%"
                        )
                        
                        InfoCard(
                            icon: "music.note",
                            title: "Spotify",
                            value: "\(cardsWithSpotify)",
                            subtitle: "\(Int((Double(cardsWithSpotify) / Double(max(filteredCards.count, 1))) * 100))%"
                        )
                        
                        if let lastSync = syncStatus.first?.lastSync {
                            InfoCard(
                                icon: "clock",
                                title: "Letztes Update",
                                value: formatDate(lastSync)
                            )
                        }
                    }
                    tableView
                }
            }
        }
    }
    
    @ViewBuilder
    private var tableView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(sortedGroupKeys, id: \.self) { key in
                    Section {
                        ForEach(groupedCards[key] ?? []) { card in
                            CardRow(card: card, sortOption: sortOption)
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
            .padding(.bottom, 10)
        }
        .searchable(text: $searchText)
        .toolbar {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)

            ToolbarSpacer(placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                Button {
                    showFilterSheet = true
                } label: { Label("New", systemImage: "line.3.horizontal.decrease")
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
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    

    struct CardRow: View {
        let card: HitsterCard
        let sortOption: SortOption
        @State private var isExpanded = false
        @State private var showPlayView = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
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
                        
                        Spacer()
                        
                        // Play Button
                        if !card.appleId.isEmpty || !card.spotifyId.isEmpty {
                            Button(action: {
                                showPlayView = true
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label {
                                    Text("ID: \(card.cardId)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                } icon: {
                                    Image(systemName: "number")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Label {
                                    Text(card.edition)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                } icon: {
                                    Image(systemName: "square.stack.3d.up")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                if !card.appleUri.isEmpty {
                                    Label {
                                        Text("Apple Music")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    } icon: {
                                        Image(systemName: "applelogo")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                
                                if !card.spotifyUri.isEmpty {
                                    Label {
                                        Text("Spotify")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                    } icon: {
                                        Image(systemName: "music.note")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background {
                if #available(iOS 18.0, *) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(isExpanded ? .regularMaterial : .thinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(isExpanded ? .white.opacity(0.15) : .white.opacity(0.05))
                }
            }
            .fullScreenCover(isPresented: $showPlayView) {
                PlayView(card: card)
            }
        }
        
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
            }
        }
    }

    struct FilterSheetView: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var selectedEdition: String
        @Binding var streamingFilter: StreamingFilter
        @Binding var sortOption: SortOption
        let editions: [String]
        
        var body: some View {
            NavigationView {
                ZStack {
                    // Pink gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.91, green: 0.18, blue: 0.49),
                            Color(red: 0.95, green: 0.25, blue: 0.55)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Edition Filter
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "square.stack.3d.up")
                                        .font(.title3)
                                    Text("Edition")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                
                                ForEach(editions, id: \.self) { edition in
                                    Button(action: {
                                        selectedEdition = edition
                                    }) {
                                        HStack {
                                            Text(edition)
                                                .font(.body)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            if selectedEdition == edition {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }
                                        .padding()
                                        .background {
                                            if #available(iOS 18.0, *) {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedEdition == edition ? .regularMaterial : .thinMaterial)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedEdition == edition ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            // Streaming Filter
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .font(.title3)
                                    Text("Streaming")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                
                                ForEach(StreamingFilter.allCases, id: \.self) { filter in
                                    Button(action: {
                                        streamingFilter = filter
                                    }) {
                                        HStack {
                                            Image(systemName: filter.icon)
                                            Text(filter.rawValue)
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            if streamingFilter == filter {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background {
                                            if #available(iOS 18.0, *) {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(streamingFilter == filter ? .regularMaterial : .thinMaterial)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(streamingFilter == filter ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            // Sort Option
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.title3)
                                    Text("Sortierung")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOption = option
                                    }) {
                                        HStack {
                                            Image(systemName: option.icon)
                                            Text(option.rawValue)
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            if sortOption == option {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background {
                                            if #available(iOS 18.0, *) {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(sortOption == option ? .regularMaterial : .thinMaterial)
                                            } else {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(sortOption == option ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .navigationTitle("Filter & Sortierung")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(red: 0.91, green: 0.18, blue: 0.49), for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    DataOverviewView()
        .modelContainer(for: [HitsterCard.self, SyncStatus.self])
}
