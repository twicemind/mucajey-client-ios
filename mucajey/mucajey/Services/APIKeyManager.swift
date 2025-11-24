import Foundation
import UIKit

class APIKeyManager {
    static let shared = APIKeyManager()
    
    private let keychainKey = "mucajeyAPIKey"
    private let deviceIdKey = "mucajeyDeviceId"
    private let baseURL = "https://api.mucajey.twicemind.com"
    
    private init() {}
    
    // Hole oder generiere Device-ID
    func getDeviceId() -> String {
        // Prüfe ob Device-ID bereits gespeichert ist
        if let savedDeviceId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return savedDeviceId
        }
        
        // Generiere neue Device-ID basierend auf identifierForVendor
        let deviceId: String
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            deviceId = vendorId
        } else {
            // Fallback: Generiere zufällige UUID
            deviceId = UUID().uuidString
        }
        
        // Speichere Device-ID
        UserDefaults.standard.set(deviceId, forKey: deviceIdKey)
        return deviceId
    }
    
    // Hole API-Key aus Keychain
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    // Speichere API-Key in Keychain
    private func saveAPIKey(_ apiKey: String) -> Bool {
        // Lösche alten Key falls vorhanden
        deleteAPIKey()
        
        guard let data = apiKey.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // Lösche API-Key aus Keychain
    private func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // Registriere App beim Server und hole API-Key
    func registerAndGetAPIKey() async throws -> String {
        // Prüfe ob bereits ein API-Key vorhanden ist
        if let existingKey = getAPIKey() {
            print("✅ API-Key aus Keychain geladen: \(existingKey.prefix(16))...")
            return existingKey
        }
        
        print("📝 Registriere App beim Server...")
        
        // Registriere bei Server
        let deviceId = getDeviceId()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        let registrationData: [String: Any] = [
            "appName": "TuneQuest iOS",
            "appVersion": appVersion,
            "deviceId": deviceId,
            "platform": "iOS"
        ]
        
        guard let url = URL(string: "\(baseURL)/api/register") else {
            print("❌ Ungültige URL: \(baseURL)/api/register")
            throw APIKeyError.invalidURL
        }
        
        print("🌐 POST \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: registrationData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Ungültige Response")
            throw APIKeyError.invalidResponse
        }
        
        print("📡 HTTP \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Server Response: \(responseString)")
            }
            throw APIKeyError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Dekodiere Response
        let decoder = JSONDecoder()
        let registrationResponse = try decoder.decode(APIKeyRegistrationResponse.self, from: data)
        
        print("✅ API-Key vom Server: \(registrationResponse.apiKey.prefix(16))... (Status: \(registrationResponse.status))")
        
        // Speichere API-Key
        guard saveAPIKey(registrationResponse.apiKey) else {
            print("❌ Fehler beim Speichern in Keychain")
            throw APIKeyError.keychainError
        }
        
        print("✅ API-Key in Keychain gespeichert")
        return registrationResponse.apiKey
    }
    
    // Erstelle URLRequest mit API-Key Header
    func createAuthenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let apiKey = getAPIKey() {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        return request
    }
}

// Response Model für Registrierung
struct APIKeyRegistrationResponse: Codable {
    let message: String
    let apiKey: String
    let appName: String
    let deviceId: String
    let createdAt: String?
    let registeredAt: String?
    let status: String // "new" oder "existing"
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
