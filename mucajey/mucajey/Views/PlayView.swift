import SwiftUI
import MusicKit
import StoreKit
import Combine

struct PlayView: View {
    let card: Card?
    let appleUri: String?
    let spotifyUri: String?
    @StateObject private var musicPlayer = MusicPlayerManager()
    
    init(card: Card) {
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
        GeometryReader { geo in
            ZStack {
                AnimatedMeshGradient()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .fill(Color.black.opacity(0.5))
                        .overlay(cardContent)
                        .shadow(color: .black.opacity(0.35), radius: 18, y: 6)
                        .frame(
                            width: min(geo.size.width * 0.88, 540),
                            height: geo.size.height * 0.40
                        )
                        .padding(.top, 20)
                    
                    Spacer()
                    
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
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            musicPlayer.stop() // 🔴 Musik endet IMMER beim Verlassen der View
        }
        .navigationTitle("Player")
        .toolbarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
    
    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 24) {
            HStack(spacing: 40) {
                Button {
                    musicPlayer.seekBackward10()
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(14)
                        .glassEffect(.clear)
                        .clipShape(Circle())
                }
                
                Button {
                    musicPlayer.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .frame(width: 86, height: 86)
                            .glassEffect(.clear)
                        Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.91, green: 0.18, blue: 0.49))
                            .offset(x: musicPlayer.isPlaying ? 0 : 3)
                    }
                }
                
                Button {
                    musicPlayer.seekForward10()
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(14)
                        .glassEffect(.clear)
                        .clipShape(Circle())
                }
            }
            
            VStack(spacing: 8) {
                ProgressView(value: musicPlayer.progress)
                    .tint(.white)
                    .frame(height: 4)
                
                HStack {
                    Text(formatTime(musicPlayer.currentTime))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(formatTime(musicPlayer.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(28)
        .onDisappear {
            musicPlayer.stop()
        }
    }
    
    private func setupPlayer() {
        if let card, !card.appleId.isEmpty {
            musicPlayer.loadAppleMusicTrack(appleId: card.appleId)
            return
        }
        if let apple = appleUri, !apple.isEmpty {
            openURLString(apple)
        }
    }
    
    private func openURLString(_ string: String) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

@MainActor
class MusicPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var errorMessage: String?
    
    private var player = SystemMusicPlayer.shared
    
    func loadAppleMusicTrack(appleId: String) {
        Task {
            guard await MusicAuthorization.request() == .authorized else {
                errorMessage = String(localized: "player.authRequired")
                return
            }
            
            do {
                let request = MusicCatalogResourceRequest<Song>(
                    matching: \.id,
                    equalTo: MusicItemID(appleId)
                )
                let response = try await request.response()
                
                if let song = response.items.first {
                    player.queue = [song]
                    duration = song.duration ?? 0
                    try await player.play()
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
    
    func togglePlayPause() {
        Task {
            do {
                if isPlaying {
                    player.pause()
                    isPlaying = false
                } else {
                    try await player.play()
                    isPlaying = true
                    startProgressTracking()
                }
            } catch {
                errorMessage = "\(String(localized: "player.playbackError")): \(error.localizedDescription)"
            }
        }
    }
    
    func seekForward10() { seek(by: 10) }
    func seekBackward10() { seek(by: -10) }
    
    private func seek(by seconds: TimeInterval) {
        let current = player.playbackTime
        guard current.isFinite else { return }
        
        let newTime = max(0, min(current + seconds, duration > 0 ? duration : current + seconds))
        player.playbackTime = newTime
        currentTime = newTime
        
        if duration > 0 {
            progress = currentTime / duration
        }
    }
    
    func stop() {
        // 👇 wirklich die Wiedergabe stoppen
        player.pause()
        
        // Queue leeren & State resetten
        player.queue = []
        isPlaying = false
        progress = 0
        currentTime = 0
        duration = 0
    }
    
    private func startProgressTracking() {
        Task {
            while isPlaying {
                let playbackTime = player.playbackTime
                if playbackTime.isFinite {
                    currentTime = playbackTime
                    if duration > 0 {
                        progress = currentTime / duration
                    }
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
}
