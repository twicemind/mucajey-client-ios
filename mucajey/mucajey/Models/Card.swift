import Foundation
import SwiftData

@Model
final class Card {
    var cardId: String = ""
    var title: String = ""
    var artist: String = ""
    var year: String = ""
    var edition: String = ""
    var languageShort: String = ""
    var languageLong: String = ""
    var appleId: String = ""
    var appleUri: String = ""
    var spotifyId: String = ""
    var spotifyUri: String = ""
    var spotifyUrl: String = ""
    var lastUpdated: Date = Date()
    
    init(
        cardId: String,
        title: String,
        artist: String,
        year: String,
        edition: String,
        languageShort: String,
        languageLong: String,
        appleId: String,
        appleUri: String,
        spotifyId: String,
        spotifyUri: String,
        spotifyUrl: String,
        lastUpdated: Date = .now
    ) {
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
final class CardSyncStatus {
    var lastSync: Date? = nil
    var isFirstSync: Bool = true
    var errorMessage: String? = nil
    
    init(lastSync: Date? = nil, isFirstSync: Bool = true, errorMessage: String? = nil) {
        self.lastSync = lastSync
        self.isFirstSync = isFirstSync
        self.errorMessage = errorMessage
    }
}
