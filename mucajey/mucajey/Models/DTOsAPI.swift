//
// API models that match the new card and edition helper endpoints returning envelopes with optional extra fields.
//

import Foundation

enum DTOModelsAPI {
    struct CardListResponse: Decodable {
        let cards: [DTOCardAPI]
    }

    struct EditionListResponse: Decodable {
        let editions: [DTOEditionAPI]
    }
    
    // Response Model für Registrierung
    struct APIKeyRegistrationResponse: Codable {
        let message: String
        let apiKey: String
        let appName: String
        let deviceId: String
        let createdAt: String?
        let registeredAt: String?
        let status: String?
    }
    
    struct AppleMappingResponse: Decodable {
        struct AppleInfo: Decodable { let id: String; let uri: String }
        struct CardInfo: Decodable {
            let id: String
            let title: String?
            let artist: String?
            let year: String?
            let apple: DTOAppleAPI?
        }
        let message: String?
        let card: DTOCardAPI?
        let apple: DTOAppleAPI?
    }

    struct DTOEditionAPI: Decodable {
        let edition: String
        let editionName: String?
        let languageShort: String?
        let languageLong: String?
        let identifier: String?
        let file: String
        let cardCount: Int?
    }

    struct DTOCardAPI: Decodable {
        let id: String
        let title: String
        let artist: String
        let year: String
        let edition: String?
        let editionName: String?
        let editionFile: String?
        let languageShort: String?
        let languageLong: String?
        let sourceFile: String?
        let apple: DTOAppleAPI?
        let spotify: DTOSpotifyAPI?
    }

    struct DTOAppleAPI: Decodable {
        let id: String?
        let uri: String?
    }

    struct DTOSpotifyAPI: Decodable {
        let id: String?
        let uri: String?
        let url: String?
    }
}
