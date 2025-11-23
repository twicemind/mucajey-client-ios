import SwiftUI
import SwiftData

struct SyncView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var syncService: DataSyncService
    @State private var showError = false
    
    init(modelContext: ModelContext) {
        _syncService = State(initialValue: DataSyncService(modelContext: modelContext))
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if syncService.isSyncing {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(LocalizedStringKey("message.loading"))
                    .font(.headline)
                    .foregroundColor(.white)
            } else if let error = syncService.syncError {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        Task {
                            await syncService.syncData()
                        }
                    }) {
                        Text("Erneut versuchen")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.91, green: 0.18, blue: 0.49))
                            .frame(width: 200, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.white)
                            )
                    }
                }
            }
            
            if let lastSync = syncService.lastSyncDate {
                Text("Zuletzt aktualisiert: \(lastSync, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .task {
            // Automatischer Sync beim Start
            await syncService.syncData()
        }
    }
}
