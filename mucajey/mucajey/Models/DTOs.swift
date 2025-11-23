import Foundation

struct AllDataResponse: Codable {
    let summary: DataSummary
    let editions: [EditionInfo]
    let cards: [CardDTO]
}

struct DataSummary: Codable {
    let totalCards: Int
    let totalEditions: Int
    let totalFiles: Int
}

struct EditionInfo: Codable {
    let edition: String
    let languageShort: String
    let languageLong: String
    let identifier: String
    let file: String
    let cardCount: Int
    
    enum CodingKeys: String, CodingKey {
        case edition
        case languageShort = "language_short"
        case languageLong = "language_long"
        case identifier
        case file
        case cardCount
    }
}

struct HitsterResponse: Codable {
    let edition: String
    let languageShort: String
    let languageLong: String
    let identifier: String
    let cards: [CardDTO]
    
    enum CodingKeys: String, CodingKey {
        case edition
        case languageShort = "language_short"
        case languageLong = "language_long"
        case identifier
        case cards
    }
}

struct CardDTO: Codable {
    let id: String
    let title: String
    let artist: String
    let year: String
    let edition: String?
    let languageShort: String?
    let languageLong: String?
    let sourceFile: String?
    let apple: MusicService
    let spotify: MusicService
    
    enum CodingKeys: String, CodingKey {
        case id, title, artist, year, edition, apple, spotify
        case languageShort = "language_short"
        case languageLong = "language_long"
        case sourceFile = "source_file"
    }
}

struct MusicService: Codable {
    let id: String
    let uri: String
}
