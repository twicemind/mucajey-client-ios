import Foundation

struct AllDataResponse: Codable {
    let summary: DataSummary
    let editions: [DTOEdition]
    let cards: [DTOCard]
}

struct DataSummary: Codable {
    let totalCards: Int
    let totalEditions: Int
    let totalFiles: Int
}

struct CardResponse: Codable {
    let edition: String
    let languageShort: String?
    let languageLong: String?
    let identifier: String?
    let cards: [DTOCard]
    
    enum CodingKeys: String, CodingKey {
        case edition
        case languageShort = "language_short"
        case languageLong = "language_long"
        case identifier
        case cards
    }
}

struct DTOCard: Codable {
    let id: String
    let title: String
    let artist: String
    let year: String
    let edition: String?
    let languageShort: String?
    let languageLong: String?
    let sourceFile: String?
    let apple: MusicService?
    let spotify: MusicService?
    
    enum CodingKeys: String, CodingKey {
        case id, title, artist, year, edition, apple, spotify
        case languageShort = "language_short"
        case languageLong = "language_long"
        case sourceFile = "source_file"
    }
}

struct DTOEdition: Codable {
    let edition: String
    let editionName: String
    let languageShort: String?
    let languageLong: String?
    let identifier: String?
    let file: String?
    let cardCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case edition
        case editionName = "edition_name"
        case languageShort = "language_short"
        case languageLong = "language_long"
        case identifier
        case file
        case cardCount
    }
}

struct MusicService: Codable {
    let id: String?
    let uri: String?
    let url: String?
}
