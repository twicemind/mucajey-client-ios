//
//  APIHandler.swift
//  mucajey
//
//  Created by Thomas Herfort on 29.11.25.
//

import Foundation

/// Common REST HTTP methods
enum RESTMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// API endpoints for the mucajey backend
enum APIEndpoint {
    // Editions
    case editions // GET /editions
    case edition(id: String) // GET /editions/{id}

    // Cards
    case cards // GET /cards
    case card(id: String) // GET /cards/{id}
    case cardMap(edition: String, id: String) // GET /cards/{id}/map
}

extension APIEndpoint {
    var path: String {
        switch self {
        case .editions:
            return "/edition/all"
        case let .edition(id):
            return "/edition/\(id)"
        case .cards:
            return "/card/all"
        case let .card(id):
            return "/card/\(id)"
        case let .cardMap(edition, id):
            return "/card/\(edition)/\(id)/apple/search"
        }
    }
    
    var method: RESTMethod {
        switch self {
        case .editions:
            return .get
        case .edition:
            return .get
        case .cards:
            return .get
        case .card:
            return .get
        case .cardMap:
            return .post
        }
    }
}

final class API {
    // Stored API key once retrieved
    static var key: String? = nil
    static var baseURL: String = "https://api.mucajey.twicemind.com"

    // Call this once at app launch (e.g., in App init or first launch flow)
    // to register and fetch the API key. Subsequent calls are no-ops if key is already set.
    static func initialize() async {
        // If already initialized, do nothing
        if key != nil { return }
        do {
            // NOTE: This assumes APIKeyManager exists elsewhere in the project
            // and that it provides an async API to register and fetch the key.
            let apiKey = try await APIKeyManager.shared.registerAndGetAPIKey()
            key = apiKey
        } catch {
            // Handle error appropriately for your app (logging, user messaging, etc.)
            print("Couldn't get API key: \(error)")
        }
    }
    
    func fetchData (apiEndpoint: APIEndpoint, label: String) async throws -> Data {
        guard let url = URL(string: "\(API.baseURL)\(apiEndpoint.path)") else {
            throw SyncError.invalidURL
        }
        
        print ("🌐 \(apiEndpoint.method.rawValue) \(url)")

        var request = URLRequest(url: url)
        request.setValue(API.key!, forHTTPHeaderField: "X-API-Key")
        request.httpMethod = apiEndpoint.method.rawValue

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.serverError
        }

        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "<none>"
        print("📥 Response (\(label)): status=\(httpResponse.statusCode), content-type=\(contentType), bytes=\(data.count)")

        if httpResponse.statusCode != 200 {
            print("❌ Server Error: HTTP \(httpResponse.statusCode) for \(label)")
            if data.isEmpty {
                print("🧾 Fehlerantwort leer")
            } else {
                logBodySnippet(data)
            }
            throw SyncError.serverError
        }

        if data.isEmpty {
            print("❌ Leerer Antwort-Body für \(label)")
            throw SyncError.decodingError
        }

        if let responseString = String(data: data, encoding: .utf8) {
            let maxLen = 2000
            let truncated = responseString.count > maxLen ? String(responseString.prefix(maxLen)) + "\n...(truncated)..." : responseString
            print("📦 Response JSON (\(label)):\n\(truncated)")
        } else {
            print("📦 Response (\(label)): <non-utf8>")
        }

        inspectJSON(data, label: label)

        return data
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
    
    private func inspectJSON(_ data: Data, label: String) {
        do {
            let anyJSON = try JSONSerialization.jsonObject(with: data, options: [])
            print("🔎 Top-level JSON type (\(label)): \(type(of: anyJSON))")
            if let dict = anyJSON as? [String: Any] {
                print("🔎 Top-level keys (\(label)): \(Array(dict.keys))")
            } else if let arr = anyJSON as? [Any] {
                print("🔎 Top-level array count (\(label)): \(arr.count)")
            }
        } catch {
            print("❌ JSON-Inspektion für \(label) fehlgeschlagen: \(error)")
        }
    }
}

final class APIEdition {
    func getAll() async throws -> Data {
        // Ensure API is initialized and key is present
        if API.key == nil {
            await API.initialize()
        }
        guard API.key != nil else {
            throw SyncError.serverError
        }
        let api = API()
        let data: Data = try await api.fetchData(apiEndpoint: .editions, label: "/edition/all")
        return data
    }
    
    func get(edition: String) async throws -> Data {
        // Ensure API is initialized and key is present
        if API.key == nil {
            await API.initialize()
        }
        guard API.key != nil else {
            throw SyncError.serverError
        }
        let api = API()
        let data: Data = try await api.fetchData(apiEndpoint: .editions, label: "/edition/\(edition)")
        return data
    }
}

final class APICard {
    
    func getAll() async throws -> Data {
        // Ensure API is initialized and key is present
        if API.key == nil {
            await API.initialize()
        }
        guard API.key != nil else {
            throw SyncError.serverError
        }
        let api = API()
        let data: Data = try await api.fetchData(apiEndpoint: .cards, label: "/card/all")
        return data
    }
    
    func get(cardID: String) async throws -> Data {
        // Ensure API is initialized and key is present
        if API.key == nil {
            await API.initialize()
        }
        guard API.key != nil else {
            throw SyncError.serverError
        }
        let api = API()
        let data: Data = try await api.fetchData(apiEndpoint: .card(id: cardID), label: "/card/\(cardID)")
        return data
    }
    
    func map(edition: String, cardID: String) async throws -> Data {
        // Ensure API is initialized and key is present
        if API.key == nil {
            await API.initialize()
        }
        guard API.key != nil else {
            throw SyncError.serverError
        }
        let api = API()
        let data: Data = try await api.fetchData(apiEndpoint: .cardMap(edition: edition, id: cardID), label: "/card/\(edition)/\(cardID)/apple/search")
        return data
    }
}

