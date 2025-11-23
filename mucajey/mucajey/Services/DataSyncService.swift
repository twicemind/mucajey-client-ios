import Foundation
import SwiftData
internal import Combine

class DataSyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var hasData = false
    
    private let baseURL = "https://tunequest.twicemind.com"
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkForExistingData()
        loadSyncStatus()
    }
    
    // Prüfe ob bereits Daten vorhanden sind
    private func checkForExistingData() {
        let descriptor = FetchDescriptor<HitsterCard>()
        if let cards = try? modelContext.fetch(descriptor) {
            hasData = !cards.isEmpty
        }
    }
    
    // Lade Sync-Status
    private func loadSyncStatus() {
        let descriptor = FetchDescriptor<SyncStatus>()
        if let status = try? modelContext.fetch(descriptor).first {
            lastSyncDate = status.lastSync
            syncError = status.errorMessage
        }
    }
    
    // Synchronisiere Daten vom Server
    func syncData() async {
        await MainActor.run {
            guard !isSyncing else { return }
            isSyncing = true
            syncError = nil
        }
        
        do {
            // Stelle sicher dass API-Key vorhanden ist
            print("🔄 Starte Datensynchronisation...")
            let apiKey = try await APIKeyManager.shared.registerAndGetAPIKey()
            
            // Daten vom Server abrufen
            guard let url = URL(string: "\(baseURL)/api/all-data") else {
                throw SyncError.invalidURL
            }
            
            print("🌐 GET \(url)")
            
            // Erstelle authentifizierten Request
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            
            print("🔑 Using API-Key: \(apiKey.prefix(16))...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SyncError.serverError
            }
            
            // Debug-Output für Fehlersuche
            if httpResponse.statusCode != 200 {
                print("❌ Server Error: HTTP \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
            
            guard httpResponse.statusCode == 200 else {
                throw SyncError.serverError
            }
            
            print("📡 HTTP 200 OK - \(data.count) bytes empfangen")
            
            // JSON dekodieren
            let decoder = JSONDecoder()
            let allDataResponse = try decoder.decode(AllDataResponse.self, from: data)
            
            print("📊 \(allDataResponse.cards.count) Karten geladen")
            
            // Daten in lokale Datenbank speichern
            try await saveToDatabase(allDataResponse)
            
            // Sync-Status aktualisieren
            updateSyncStatus(success: true)
            
            await MainActor.run {
                lastSyncDate = Date()
                hasData = true
            }
            
        } catch {
            let errorMsg = handleError(error)
            await MainActor.run {
                syncError = errorMsg
            }
            updateSyncStatus(success: false, error: errorMsg)
        }
        
        await MainActor.run {
            isSyncing = false
        }
    }
    
    // Speichere Daten in der Datenbank
    private func saveToDatabase(_ response: AllDataResponse) async throws {
        // Lösche alte Daten
        let deleteDescriptor = FetchDescriptor<HitsterCard>()
        let existingCards = try modelContext.fetch(deleteDescriptor)
        for card in existingCards {
            modelContext.delete(card)
        }
        
        // Füge neue Daten hinzu
        for cardDTO in response.cards {
            let card = HitsterCard(
                cardId: cardDTO.id,
                title: cardDTO.title,
                artist: cardDTO.artist,
                year: cardDTO.year,
                edition: cardDTO.edition ?? "Unknown",
                languageShort: cardDTO.languageShort ?? "de",
                languageLong: cardDTO.languageLong ?? "Deutsch",
                appleId: cardDTO.apple.id,
                appleUri: cardDTO.apple.uri,
                spotifyId: cardDTO.spotify.id,
                spotifyUri: cardDTO.spotify.uri,
                lastUpdated: Date()
            )
            modelContext.insert(card)
        }
        
        try modelContext.save()
    }
    
    // Aktualisiere Sync-Status
    private func updateSyncStatus(success: Bool, error: String? = nil) {
        let descriptor = FetchDescriptor<SyncStatus>()
        let status = (try? modelContext.fetch(descriptor).first) ?? SyncStatus()
        
        status.lastSync = success ? Date() : status.lastSync
        status.isFirstSync = false
        status.errorMessage = error
        
        modelContext.insert(status)
        try? modelContext.save()
    }
    
    // Fehlerbehandlung
    private func handleError(_ error: Error) -> String {
        // API-Key Fehler
        if let apiKeyError = error as? APIKeyError {
            print("❌ API-Key Error: \(apiKeyError.localizedDescription)")
            return apiKeyError.localizedDescription
        }
        
        // Sync Fehler
        if let syncError = error as? SyncError {
            return syncError.localizedDescription
        }
        
        // URL Fehler
        if let urlError = error as? URLError {
            print("❌ URL Error: \(urlError.code.rawValue) - \(urlError.localizedDescription)")
            switch urlError.code {
            case .notConnectedToInternet:
                return NSLocalizedString("message.noInternet", value: "Keine Internetverbindung", comment: "")
            case .timedOut:
                return NSLocalizedString("message.timeout", value: "Zeitüberschreitung", comment: "")
            case .cannotConnectToHost:
                return "Server nicht erreichbar. Prüfen Sie die Server-Adresse."
            default:
                return NSLocalizedString("message.networkError", value: "Netzwerkfehler. Bitte versuchen Sie es erneut.", comment: "")
            }
        }
        
        // Allgemeine Fehler
        print("❌ General Error: \(error.localizedDescription)")
        return error.localizedDescription
    }
    
    // Hole alle Karten aus der lokalen Datenbank
    func getAllCards() throws -> [HitsterCard] {
        let descriptor = FetchDescriptor<HitsterCard>(
            sortBy: [SortDescriptor(\.year)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // Suche Karte nach Karten-ID (nicht uniqueId)
    func getCard(by cardId: String) throws -> HitsterCard? {
        let descriptor = FetchDescriptor<HitsterCard>(
            predicate: #Predicate { card in
                card.cardId == cardId
            }
        )
        return try modelContext.fetch(descriptor).first
    }
}

enum SyncError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error.invalidURL", value: "Ungültige Server-URL", comment: "")
        case .serverError:
            return NSLocalizedString("error.serverError", value: "Server-Fehler", comment: "")
        case .decodingError:
            return NSLocalizedString("error.decodingError", value: "Fehler beim Verarbeiten der Daten", comment: "")
        }
    }
}
