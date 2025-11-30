//
//  ErrorHandler.swift
//  mucajey
//
//  Created by Thomas Herfort on 29.11.25.
//

import Foundation

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
