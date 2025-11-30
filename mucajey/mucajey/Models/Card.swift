import Foundation
import SwiftData

@Model
final class HitsterCard {
    @Attribute(.unique) var uniqueId: String // Zusammengesetzte ID aus cardId + edition
    var cardId: String // Original Karten-ID
    var title: String
    var artist: String
    var year: String
    var edition: String
    var languageShort: String
    var languageLong: String
    var appleId: String
    var appleUri: String
    var spotifyId: String
    var spotifyUri: String
    var spotifyUrl: String
    var lastUpdated: Date
    
    init(cardId: String, title: String, artist: String, year: String, edition: String, languageShort: String, languageLong: String, appleId: String, appleUri: String, spotifyId: String, spotifyUri: String, spotifyUrl: String, lastUpdated: Date = Date()) {
        self.uniqueId = "\(edition)_\(cardId)" // Zusammengesetzte eindeutige ID
        self.cardId = cardId
        self.title = title
        self.artist = artist
        self.year = year
        self.edition = edition
        self.languageShort = languageShort
        self.languageLong = languageLong
        self.appleId = appleId
        self.appleUri = appleUri
        self.spotifyId = spotifyId
        self.spotifyUri = spotifyUri
        self.spotifyUrl = spotifyUrl
        self.lastUpdated = lastUpdated
    }
}

@Model
final class SyncStatus {
    @Attribute(.unique) var id: String
    var lastSync: Date?
    var isFirstSync: Bool
    var errorMessage: String?
    
    init(id: String = "sync_status", lastSync: Date? = nil, isFirstSync: Bool = true, errorMessage: String? = nil) {
        self.id = id
        self.lastSync = lastSync
        self.isFirstSync = isFirstSync
        self.errorMessage = errorMessage
    }
}
