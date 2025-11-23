import SwiftUI
import SwiftData
import WebKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Namespace private var transition
    @State private var syncService: DataSyncService?
    @State private var showSyncView = true
    @State private var showDataOverview = false
    @State private var showQRScanner = false    
    @State private var page = WebPage()
    @State private var query: String = ""
    @SceneStorage("selectedTab") var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("start.startGame", systemImage: "play.circle.fill", value: 0) {
                ZStack {
                    AnimatedMeshGradient()
                        .ignoresSafeArea(edges: .all)
                    // Zeige Sync-View beim ersten Start oder wenn Daten aktualisiert werden
                    if let syncService = syncService {
                        if showSyncView && (syncService.isSyncing || syncService.syncError != nil) {
                            SyncView(modelContext: modelContext)
                                .onReceive(syncService.$hasData) { hasData in
                                    if hasData && !syncService.isSyncing && syncService.syncError == nil {
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
            /* Tab("start.moreHitster", systemImage: "plus.circle.fill") {
                WebView(page)
                    .onAppear {
                        page.load(URLRequest(url: URL(string: "https://hitstergame.com/de-de/produkte/")!))
                    }
            }
            Tab("nav.help", systemImage: "apple.podcasts.pages.fill") {
                WebView(page)
                    .onAppear {
                        page.load(URLRequest(url: URL(string: "https://hitstergame.com/de-de/faq/")!))
                    }
            }*/
            /*Tab("start.instructions", systemImage: "music.note.square.stack", value: 2) {
                CardListView()
            }
            if selectedTab == 2 || selectedTab == 3 {
                Tab("start.instructions", systemImage: "magnifyingglass", value: 3, role: .search) {
                    CardListView()
                }
            }*/
            Tab("start.instructions", systemImage: "music.note.square.stack", value: 2) {
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
            // Automatischer Sync beim Start
            if let syncService = syncService {
                await syncService.syncData()
            }
        }
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView()
        }
    }
    
    private var mainContent: some View {
        Group {
            if let syncService = syncService {
                // Main content
                VStack(spacing: 30) {
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
                    
                    // Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showQRScanner = true
                        }) {
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
    StartScreenView()
}
