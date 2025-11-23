import SwiftUI
import MusicKit
import StoreKit
internal import Combine

struct PlayView: View {
    let card: HitsterCard?
    let appleUri: String?
    let spotifyUri: String?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var musicPlayer = MusicPlayerManager()
    @State private var showQRScanner = false
    
    init(card: HitsterCard) {
        self.card = card
        self.appleUri = card.appleUri
        self.spotifyUri = card.spotifyUri
    }
    
    init(appleUri: String?, spotifyUri: String?) {
        self.card = nil
        self.appleUri = appleUri
        self.spotifyUri = spotifyUri
    }
    
    var body: some View {
        ZStack {
            // Pink gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.91, green: 0.18, blue: 0.49),
                    Color(red: 0.95, green: 0.25, blue: 0.55)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                            Text(LocalizedStringKey("nav.back"))
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                Spacer()
                
                // Card Display
                VStack(spacing: 24) {
                    // Album Art Placeholder
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.2))
                        .frame(width: 280, height: 280)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Song Info
                    VStack(spacing: 8) {
                        Text(card?.title ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(card?.artist ?? "")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        Text(card?.year ?? "")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 40)
                    
                    // Player Controls
                    VStack(spacing: 32) {
                        // Progress Bar (placeholder)
                        VStack(spacing: 8) {
                            ProgressView(value: musicPlayer.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .frame(height: 4)
                            
                            HStack {
                                Text(formatTime(musicPlayer.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Spacer()
                                
                                Text(formatTime(musicPlayer.duration))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        // Play/Pause Button
                        HStack(spacing: 40) {
                            Button(action: {
                                musicPlayer.skipBackward()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                musicPlayer.togglePlayPause()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    
                                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(Color(red: 0.91, green: 0.18, blue: 0.49))
                                        .offset(x: musicPlayer.isPlaying ? 0 : 3)
                                }
                            }
                            
                            Button(action: {
                                musicPlayer.skipForward()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Service Info
                HStack(spacing: 16) {
                    if let apple = appleUri, !apple.isEmpty {
                        Button(action: {
                            openURLString(apple)
                        }) {
                            HStack {
                                Image(systemName: "applelogo")
                                Text(LocalizedStringKey("player.openAppleMusic"))
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.white.opacity(0.3))
                            )
                        }
                    }
                    
                    if let spotify = spotifyUri, !spotify.isEmpty {
                        Button(action: {
                            openURLString(spotify)
                        }) {
                            HStack {
                                Image(systemName: "music.note")
                                Text(LocalizedStringKey("player.openSpotify"))
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.white.opacity(0.3))
                            )
                        }
                    }
                }
                .padding(.bottom, 40)
                
                // Error Message
                if let error = musicPlayer.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.red.opacity(0.3))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            musicPlayer.stop()
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Swipe right to left (negative translation)
                    if value.translation.width < -50 {
                        musicPlayer.stop()
                        dismiss()
                        // Kurze Verzögerung, dann Scanner öffnen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showQRScanner = true
                        }
                    }
                }
        )
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView()
        }
    }
    
    private func setupPlayer() {
        // Prefer Apple Music by ID if available, else try URIs
        if let card, !card.appleId.isEmpty {
            musicPlayer.loadAppleMusicTrack(appleId: card.appleId)
            return
        }
        if let apple = appleUri, !apple.isEmpty {
            openURLString(apple)
            return
        }
        if let card, !card.spotifyId.isEmpty {
            musicPlayer.loadSpotifyTrack(spotifyId: card.spotifyId)
            return
        }
        if let spotify = spotifyUri, !spotify.isEmpty {
            openURLString(spotify)
            return
        }
    }
    
    private func openURLString(_ string: String) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// Music Player Manager
@MainActor
class MusicPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var errorMessage: String?
    
    private var player: SystemMusicPlayer?
    private var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined
    
    init() {
        player = SystemMusicPlayer.shared
    }
    
    func loadAppleMusicTrack(appleId: String) {
        Task {
            // Check authorization
            musicAuthorizationStatus = await MusicAuthorization.request()
            
            guard musicAuthorizationStatus == .authorized else {
                errorMessage = String(localized: "player.authRequired")
                return
            }
            
            do {
                // Search for track by ID
                let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(appleId))
                let response = try await request.response()
                
                if let song = response.items.first {
                    player?.queue = [song]
                    duration = song.duration ?? 0
                    try await player?.play()
                    isPlaying = true
                    startProgressTracking()
                } else {
                    errorMessage = String(localized: "player.songNotFound")
                }
            } catch {
                errorMessage = "\(String(localized: "player.loadError")): \(error.localizedDescription)"
            }
        }
    }
    
    func loadSpotifyTrack(spotifyId: String) {
        // Spotify SDK würde hier verwendet werden
        // Für jetzt öffnen wir nur die Spotify App
        errorMessage = String(localized: "player.spotifyRequired")
    }
    
    func togglePlayPause() {
        Task {
            do {
                if isPlaying {
                    player?.pause()
                    isPlaying = false
                } else {
                    try await player?.play()
                    isPlaying = true
                    startProgressTracking()
                }
            } catch {
                errorMessage = "\(String(localized: "player.playbackError")): \(error.localizedDescription)"
            }
        }
    }
    
    func skipForward() {
        Task {
            try? await player?.skipToNextEntry()
        }
    }
    
    func skipBackward() {
        Task {
            try? await player?.skipToPreviousEntry()
        }
    }
    
    func stop() {
        player?.queue = []
        isPlaying = false
    }
    
    private func startProgressTracking() {
        Task {
            while isPlaying {
                if let playbackTime = player?.playbackTime {
                    currentTime = playbackTime
                    if duration > 0 {
                        progress = currentTime / duration
                    }
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
}
