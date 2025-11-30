//
//  mucajeyApp.swift
//  mucajey
//
//  Created by Thomas Herfort on 23.11.25.
//

import SwiftUI
import SwiftData

@main
struct mucajeyApp: App {
    @State private var isInitialized = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Card.self,
            Edition.self,
            CardSyncStatus.self,
            EditionSyncStatus.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Bei Schemaänderungen: Lösche den alten Store und erstelle einen neuen
            print("⚠️ ModelContainer konnte nicht geladen werden: \(error)")
            print("🔄 Versuche Store zu löschen und neu zu erstellen...")
            
            // Lösche den alten Store
            let url = modelConfiguration.url
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
                print("🗑️ Alter Store gelöscht: \(url.path)")
            } else {
                print("ℹ️ Kein bestehender Store gefunden unter: \(url.path)")
            }
            
            // Versuche erneut
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ ModelContainer erfolgreich neu erstellt")
                return container
            } catch {
                fatalError("Could not create ModelContainer after cleanup: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .task {
                    await initializeApp()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Initialisiere App beim ersten Start
    private func initializeApp() async {
        guard !isInitialized else { return }
        
        do {
            // Registriere beim Server und hole API-Key
            let apiKey = try await APIKeyManager.shared.registerAndGetAPIKey()
            let deviceId = APIKeyManager.shared.getDeviceId()
            
            print("✅ App initialisiert")
            print("📱 Device-ID: \(deviceId)")
            print("🔑 API-Key vorhanden: \(apiKey.prefix(16))...")
            
            isInitialized = true
        } catch {
            print("❌ Fehler bei App-Initialisierung: \(error.localizedDescription)")
            // App kann trotzdem weiterlaufen, Sync wird später fehlschlagen
            isInitialized = true
        }
    }
}

