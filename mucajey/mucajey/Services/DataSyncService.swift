//
//  DataSync.swift
//  mucajey
//
//  Created by Thomas Herfort on 24.11.25.
//

import Foundation
import SwiftData
import Combine

@MainActor
class DataSyncService: ObservableObject {
    @Published var isCardSyncing = false
    @Published var isEditionSyncing = false
    @Published var lastCardSyncDate: Date?
    @Published var lastEditionSyncDate: Date?
    @Published var syncCardError: String?
    @Published var syncEditionError: String?
    @Published var hasCardData = false
    @Published var hasEditionData: Bool = false
    
    private let modelContext: ModelContext
    private let dataHandler: DatabaseHandler
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataHandler = DatabaseHandler(modelContext: modelContext)
        hasCardData = dataHandler.checkForExistingCardData()
        cardSyncStatus()
        hasEditionData = dataHandler.checkForExistingEditionData()
        editionSyncStatus()
    }
    
    // Lade Sync-Status
    private func cardSyncStatus() {
        let status = dataHandler.loadCardSyncStatus()
        lastCardSyncDate = status.lastSync
        syncCardError = status.errorMessage
    }
    
    // Lade Sync-Status
    private func editionSyncStatus() {
        let status = dataHandler.loadEditionSyncStatus()
        lastEditionSyncDate = status.lastSync
        syncEditionError = status.errorMessage
    }
    
    func syncDataEdition() async throws {
        await MainActor.run {
            guard !isEditionSyncing else { return }
            isEditionSyncing = true
            syncEditionError = nil
        }
        
        do {
            print("🔄 Starte Datensynchronisation...Edition")
            
            let editions = try await fetchEditions()
                  
            print("📚 \(editions.count) Editionen gefunden")
            if let firstEdition = editions.first {
                print("  erste Edition: \(firstEdition.edition) (\(firstEdition.file)) - \(firstEdition.cardCount ?? 0) Karten")
            }
            
            try await dataHandler.saveEditionToDatabase(editions)
            
            dataHandler.updateEditionSyncStatus(success: true)
            
            await MainActor.run {
                lastEditionSyncDate = Date()
                hasEditionData = true
            }
        } catch {
            let errorMsg = ErrorHandler().handleError(error)
            await MainActor.run {
                syncEditionError = errorMsg
            }
            dataHandler.updateEditionSyncStatus(success: false, error: errorMsg)
        }

        await MainActor.run {
            isEditionSyncing = false
        }
    }
    
    // Synchronisiere Daten vom Server
    func syncDataCard() async throws {
        await MainActor.run {
            guard !isCardSyncing else { return }
            isCardSyncing = true
            syncCardError = nil
        }

        do {
            print("🔄 Starte Datensynchronisation...")

            let cards = try await fetchCards()
            
            print("📊 \(cards.count) Karten empfangen")
            if let firstCard = cards.first {
                print("  erste Karte: id=\(firstCard.id), title=\(firstCard.title), artist=\(firstCard.artist), year=\(firstCard.year)")
            } else {
                print("⚠️ Keine Karten im Response")
            }

            try await dataHandler.saveCardToDatabase(cards)

            dataHandler.updateCardSyncStatus(success: true)

            await MainActor.run {
                lastCardSyncDate = Date()
                hasCardData = true
            }
        } catch {
            let errorMsg = ErrorHandler().handleError(error)
            await MainActor.run {
                syncCardError = errorMsg
            }
            dataHandler.updateCardSyncStatus(success: false, error: errorMsg)
        }

        await MainActor.run {
            isCardSyncing = false
        }
    }
    
    // Helper to print a safe snippet of the response body for debugging
    func logBodySnippet(_ data: Data) {
        if let s = String(data: data, encoding: .utf8) {
            let maxLen = 800
            let snippet = s.count > maxLen ? String(s.prefix(maxLen)) + "\n...(truncated)..." : s
            print("📄 Body snippet:\n\(snippet)")
        } else {
            print("📄 Body snippet: <non-utf8>")
        }
    }

    private func fetchCards() async throws -> [DTOModelsAPI.DTOCardAPI] {
        let data = try await APICard().getAll()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let cardList = try decoder.decode(DTOModelsAPI.CardListResponse.self, from: data)
            return cardList.cards
        } catch {
            print("❌ Fehler beim Dekodieren des CardListResponse: \(error)")
            logBodySnippet(data)
            throw SyncError.decodingError
        }
    }

    private func fetchEditions() async throws -> [DTOModelsAPI.DTOEditionAPI] {
        let data = try await APIEdition().getAll()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let editionList = try decoder.decode(DTOModelsAPI.EditionListResponse.self, from: data)
            return editionList.editions
        } catch {
            print("❌ Fehler beim Dekodieren des EditionListResponse: \(error)")
            logBodySnippet(data)
            throw SyncError.decodingError
        }
    }
}

