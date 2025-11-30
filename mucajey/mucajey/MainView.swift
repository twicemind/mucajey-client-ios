import SwiftUI
import SwiftData
import WebKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Namespace private var transition
    @State private var syncService: DataSyncService?
    @State private var showSyncView = true
    @State private var showDataOverview = false
    @State private var page = WebPage()
    @State private var query: String = ""
    @SceneStorage("selectedTab") var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("start.startGame", systemImage: "play.circle.fill", value: 0) {
                // 👉 NavigationStack ergänzt
                NavigationStack {
                    ZStack {
                        AnimatedMeshGradient()
                            .ignoresSafeArea(edges: .all)
                        
                        if let syncService = syncService {
                            if showSyncView && (syncService.isCardSyncing || syncService.syncCardError != nil) && (syncService.isEditionSyncing || syncService.syncEditionError != nil) {
                                SyncView(modelContext: modelContext)
                                    .onReceive(syncService.$hasCardData) { hasData in
                                        if hasData && !syncService.isCardSyncing && syncService.syncCardError == nil && !syncService.isEditionSyncing && syncService.syncEditionError == nil {
                                            withAnimation {
                                                showSyncView = false
                                            }
                                        }
                                    }
                            } else {
                                mainContent
                            }
                        }
                    }
                }
            }
            
            Tab("start.instructions", systemImage: "note", value: 1) {
                NavigationStack {
                    WebView(page)
                        .onAppear {
                            page.load(URLRequest(url: URL(string: "https://hitstergame.com/de-de/spielmodus-auswaehlen-premium/")!))
                        }
                        .navigationTitle("Instructions")
                        .toolbarTitleDisplayMode(.inline)
                }
            }
            
            Tab("start.cards", systemImage: "music.note.square.stack", value: 2) {
                NavigationStack {
                    EditionList()
                        .background(AnimatedMeshGradient())
                        .navigationTitle("Editions")
                        .toolbarTitleDisplayMode(.automatic)
                        .scrollContentBackground(.hidden)
                }
                .tabBarMinimizeBehavior(.automatic)
            }
        }
        .tabBarMinimizeBehavior(.automatic)
        .onAppear {
            if syncService == nil {
                syncService = DataSyncService(modelContext: modelContext)
            }
        }
        .task {
            if let syncService = syncService {
                try? await syncService.syncDataCard()
                try? await syncService.syncDataEdition()
            }
        }
    }
    
    private var mainContent: some View {
        Group {
            if let _ = syncService {
                VStack(spacing: 30) {
                    Image("launchscreen")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320)
                        .shadow(radius: 24)
                    
                    VStack(spacing: 10) {
                        Text(LocalizedStringKey("start.title"))
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(2)
                            .shadow(radius: 16)

                        Text(LocalizedStringKey("start.subtitle"))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(radius: 16)
                    }
                    .padding(.bottom, 40)
                    
                    // 👉 Hier NavigationLink statt Button + fullScreenCover
                    VStack(spacing: 16) {
                        NavigationLink {
                            QRScannerView()
                        } label: {
                            Text(LocalizedStringKey("start.startGame"))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 65)
                                .shadow(radius: 16)
                        }
                        .glassEffect(Glass.clear)
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }
}

#Preview {
    MainView()
}
