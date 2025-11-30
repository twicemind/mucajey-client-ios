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

// Fehler-Typen
enum APIKeyError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case keychainError
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error.apiKey.invalidURL", value: "Ungültige Server-URL", comment: "")
        case .invalidResponse:
            return NSLocalizedString("error.apiKey.invalidResponse", value: "Ungültige Server-Antwort", comment: "")
        case .serverError(let statusCode):
            return NSLocalizedString("error.apiKey.serverError", value: "Server-Fehler (Code: \(statusCode))", comment: "")
        case .keychainError:
            return NSLocalizedString("error.apiKey.keychainError", value: "Fehler beim Speichern des API-Keys", comment: "")
        case .noAPIKey:
            return NSLocalizedString("error.apiKey.noAPIKey", value: "Kein API-Key vorhanden", comment: "")
        }
    }
}

@MainActor
final class ErrorHandler {
    // Fehlerbehandlung
    func handleError(_ error: Error) -> String {
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
}
