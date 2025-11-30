//
//  DatabaseHandler.swift
//  mucajey
//
//  Created by Thomas Herfort on 29.11.25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DatabaseHandler {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Speichere Daten in der Datenbank
    func saveEditionToDatabase(_ editions: [DTOModelsAPI.DTOEditionAPI]) async throws {
        // Lösche alte Daten
        let deleteDescriptor = FetchDescriptor<Edition>()
        let existingEditions = try modelContext.fetch(deleteDescriptor)
        for edition in existingEditions {
            modelContext.delete(edition)
        }
        
        // NOTE: This code assumes DTO properties may be optional and applies safe defaults.
        // To fully support this, update APIModels DTO definitions to make fields optional where the server
        // may omit them (e.g., title, artist, year, apple/spotify fields).
        // Füge neue Daten hinzu
        for editionDTO in editions {
            let edition = Edition(
                edition: editionDTO.edition,
                editionName: editionDTO.editionName ?? editionDTO.edition,
                languageShort: editionDTO.languageShort ?? "de",
                languageLong: editionDTO.languageLong ?? "Deutsch",
                identifier: editionDTO.identifier ?? "n.A.",
                file: editionDTO.file,
                cardCount: editionDTO.cardCount ?? 0,
                lastUpdated: Date()
            )
            modelContext.insert(edition)
        }
        
        try modelContext.save()
    }
    
    // Speichere Daten in der Datenbank
    func saveCardToDatabase(_ cards: [DTOModelsAPI.DTOCardAPI]) async throws {
        // Lösche alte Daten
        let deleteDescriptor = FetchDescriptor<Card>()
        let existingCards = try modelContext.fetch(deleteDescriptor)
        for card in existingCards {
            modelContext.delete(card)
        }
        
        // NOTE: This code assumes DTO properties may be optional and applies safe defaults.
        // To fully support this, update APIModels DTO definitions to make fields optional where the server
        // may omit them (e.g., title, artist, year, apple/spotify fields).
        // Füge neue Daten hinzu
        for cardDTO in cards {
            let card = Card(
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
    func updateCardSyncStatus(success: Bool, error: String? = nil) {
        let descriptor = FetchDescriptor<CardSyncStatus>()
        let status = (try? modelContext.fetch(descriptor).first) ?? CardSyncStatus()
        
        status.lastSync = success ? Date() : status.lastSync
        status.isFirstSync = false
        status.errorMessage = error
        
        modelContext.insert(status)
        try? modelContext.save()
    }
    
    // Aktualisiere Sync-Status
    func updateEditionSyncStatus(success: Bool, error: String? = nil) {
        let descriptor = FetchDescriptor<EditionSyncStatus>()
        let status = (try? modelContext.fetch(descriptor).first) ?? EditionSyncStatus()
        
        status.lastSync = success ? Date() : status.lastSync
        status.isFirstSync = false
        status.errorMessage = error
        
        modelContext.insert(status)
        try? modelContext.save()
    }
    
    // Prüfe ob bereits Daten vorhanden sind
    func checkForExistingCardData() -> Bool {
        let descriptor = FetchDescriptor<Card>()
        if let cards = try? modelContext.fetch(descriptor) {
            return !cards.isEmpty
        }
        return false
    }
    
    // Prüfe ob bereits Daten vorhanden sind
    func checkForExistingEditionData() -> Bool {
        let descriptor = FetchDescriptor<Edition>()
        if let editions = try? modelContext.fetch(descriptor) {
            return !editions.isEmpty
        }
        return false
    }
    
    // Lade Sync-Status
    func loadCardSyncStatus() -> CardSyncStatus {
        let descriptor = FetchDescriptor<CardSyncStatus>()
        if let status = try? modelContext.fetch(descriptor).first {
            return status
        }
        let status = CardSyncStatus()
        modelContext.insert(status)
        try? modelContext.save()
        return status
    }
    
    // Lade Sync-Status
    func loadEditionSyncStatus() -> EditionSyncStatus {
        let descriptor = FetchDescriptor<EditionSyncStatus>()
        if let status = try? modelContext.fetch(descriptor).first {
            return status
        }
        let status = EditionSyncStatus()
        modelContext.insert(status)
        try? modelContext.save()
        return status
    }
    
    // Hole alle Karten aus der lokalen Datenbank
    func getAllCards() throws -> [Card] {
        let descriptor = FetchDescriptor<Card>(
            sortBy: [SortDescriptor(\.year)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // Hole alle Karten aus der lokalen Datenbank
    func getAllEditions() throws -> [Edition] {
        let descriptor = FetchDescriptor<Edition>(
            sortBy: [SortDescriptor(\.identifier)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // Suche Karte nach Karten-ID (nicht uniqueId)
    func getCard(by cardId: String) throws -> Card? {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                card.cardId == cardId
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // Suche Karte nach Karten-ID (nicht uniqueId)
    func getEdition(by editionIdentifier: String) throws -> Edition? {
        let descriptor = FetchDescriptor<Edition>(
            predicate: #Predicate { edition in
                edition.identifier == editionIdentifier
            }
        )
        return try modelContext.fetch(descriptor).first
    }
}
