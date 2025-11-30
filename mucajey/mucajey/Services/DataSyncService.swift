//
//  DataSync.swift
//  mucajey
//
//  Created by Thomas Herfort on 24.11.25.
//

import Foundation
import SwiftData
import Combine

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

@MainActor
class DataSync: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var hasData = false
    
    private let baseURL = "https://api.mucajey.twicemind.com"
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
    func syncData() async throws{
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
            guard let url = URL(string: "\(baseURL)/api/files/all-data") else {
                throw SyncError.invalidURL
            }
            
            print("🌐 GET \(url)")
            
            // Erstelle authentifizierten Request
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            
            print("🔑 Using API-Key: \(apiKey.prefix(16))...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Response diagnostics
            if let http = response as? HTTPURLResponse {
                let contentType = http.value(forHTTPHeaderField: "Content-Type") ?? "<none>"
                print("📥 Response: status=\(http.statusCode), content-type=\(contentType), bytes=\(data.count)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SyncError.serverError
            }
            
            // Debug-Output für Fehlersuche
            if httpResponse.statusCode != 200 {
                print("❌ Server Error: HTTP \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    print("🧾 Error Body (utf8):\n\(responseString)")
                } else {
                    print("🧾 Error Body: <empty or non-utf8>")
                }
            }
            
            guard httpResponse.statusCode == 200 else {
                throw SyncError.serverError
            }
            
            print("📡 HTTP 200 OK - \(data.count) bytes empfangen")
            
            // Guard against empty or whitespace-only bodies
            if data.isEmpty || (String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true) {
                print("❌ Empty response body from server for URL: \(url)")
                throw SyncError.decodingError
            }
            
            // JSON dekodieren
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // Temporary: log response body to inspect schema (truncated if very large)
            if let responseString = String(data: data, encoding: .utf8) {
                let maxLen = 4000
                let truncated = responseString.count > maxLen ? String(responseString.prefix(maxLen)) + "\n…(truncated)…" : responseString
                print("📦 Response JSON (utf8):\n\(truncated)")
            }
            
            // Temporary: generic JSON inspection to understand top-level structure
            do {
                let anyJSON = try JSONSerialization.jsonObject(with: data, options: [])
                print("🔎 Top-level JSON type: \(type(of: anyJSON))")
                if let dict = anyJSON as? [String: Any] {
                    print("🔎 Top-level keys: \(Array(dict.keys))")
                } else if let arr = anyJSON as? [Any] {
                    print("🔎 Top-level array count: \(arr.count)")
                }
            } catch {
                print("❌ Not valid JSON (preflight inspection): \(error)")
            }
            
            // Decode with detailed error reporting
            let allDataResponse: AllDataResponse
            do {
                allDataResponse = try decoder.decode(AllDataResponse.self, from: data)
            } catch let DecodingError.keyNotFound(key, context) {
                print("❌ Key not found: \(key.stringValue), context: \(context.debugDescription), codingPath: \(context.codingPath)")
                logBodySnippet(data)
                if let http = response as? HTTPURLResponse {
                    print("ℹ️ Content-Type during failure: \(http.value(forHTTPHeaderField: "Content-Type") ?? "<none>")")
                }
                throw SyncError.decodingError
            } catch let DecodingError.typeMismatch(type, context) {
                print("❌ Type mismatch for \(type), context: \(context.debugDescription), codingPath: \(context.codingPath)")
                logBodySnippet(data)
                if let http = response as? HTTPURLResponse {
                    print("ℹ️ Content-Type during failure: \(http.value(forHTTPHeaderField: "Content-Type") ?? "<none>")")
                }
                throw SyncError.decodingError
            } catch let DecodingError.valueNotFound(value, context) {
                print("❌ Value not found: \(value), context: \(context.debugDescription), codingPath: \(context.codingPath)")
                logBodySnippet(data)
                if let http = response as? HTTPURLResponse {
                    print("ℹ️ Content-Type during failure: \(http.value(forHTTPHeaderField: "Content-Type") ?? "<none>")")
                }
                throw SyncError.decodingError
            } catch let DecodingError.dataCorrupted(context) {
                print("❌ Data corrupted: \(context.debugDescription), codingPath: \(context.codingPath)")
                logBodySnippet(data)
                if let http = response as? HTTPURLResponse {
                    print("ℹ️ Content-Type during failure: \(http.value(forHTTPHeaderField: "Content-Type") ?? "<none>")")
                }
                throw SyncError.decodingError
            } catch {
                print("❌ General decoding error: \(error)")
                logBodySnippet(data)
                if let http = response as? HTTPURLResponse {
                    print("ℹ️ Content-Type during failure: \(http.value(forHTTPHeaderField: "Content-Type") ?? "<none>")")
                }
                print("ℹ️ Decoding failed: Response body did not match APIModels.AllDataResponse schema.")
                throw SyncError.decodingError
            }
            
            print("📊 \(allDataResponse.cards.count) Karten geladen")
            
            // Pretty print the decoded response for debugging (without requiring Encodable)
            print("🧾 Decoded AllDataResponse summary:")
            print("  cards: \(allDataResponse.cards.count)")
            if let first = allDataResponse.cards.first {
                print("  first card: id=\(first.id), title=\(first.title), artist=\(first.artist), year=\(first.year)")
            }
            if allDataResponse.cards.isEmpty {
                print("⚠️ Decoded successfully but 'cards' is empty.")
            }
            
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
        
        await MainActor.run {
            isSyncing = false
        }
    }
    
    // Helper to print a safe snippet of the response body for debugging
    func logBodySnippet(_ data: Data) {
        if let s = String(data: data, encoding: .utf8) {
            let maxLen = 800
            let snippet = s.count > maxLen ? String(s.prefix(maxLen)) + "\n…(truncated)…" : s
            print("📄 Body snippet:\n\(snippet)")
        } else {
            print("📄 Body snippet: <non-utf8>")
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
        
        // NOTE: This code assumes DTO properties may be optional and applies safe defaults.
        // To fully support this, update APIModels DTO definitions to make fields optional where the server
        // may omit them (e.g., title, artist, year, apple/spotify fields).
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
                appleId: cardDTO.apple?.id ?? "",
                appleUri: cardDTO.apple?.uri ?? "",
                spotifyId: cardDTO.spotify?.id ?? "",
                spotifyUri: cardDTO.spotify?.uri ?? "",
                spotifyUrl: cardDTO.spotify?.url ?? "",
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
