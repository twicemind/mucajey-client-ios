import Foundation
import SwiftData

@Model
final class Edition {
    var edition: String = ""
    var editionName: String = ""
    var languageShort: String = ""
    var languageLong: String = ""
    var identifier: String = ""
    var file: String = ""
    var cardCount: Int = 0
    var lastUpdated: Date = Date()
    
    init(edition: String, editionName: String, languageShort: String, languageLong: String, identifier: String, file: String, cardCount: Int, lastUpdated: Date = Date()) {
        self.edition = edition
        self.editionName = editionName
        self.identifier = identifier
        self.file = file
        self.languageShort = languageShort
        self.languageLong = languageLong
        self.cardCount = cardCount
        self.lastUpdated = lastUpdated
    }
}

@Model
final class EditionSyncStatus {
    var lastSync: Date? = nil
    var isFirstSync: Bool = true
    var errorMessage: String? = nil
    
    init(lastSync: Date? = nil, isFirstSync: Bool = true, errorMessage: String? = nil) {
        self.lastSync = lastSync
        self.isFirstSync = isFirstSync
        self.errorMessage = errorMessage
    }
}
