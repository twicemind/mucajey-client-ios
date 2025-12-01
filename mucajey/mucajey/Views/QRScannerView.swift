import SwiftUI
@preconcurrency import AVFoundation
import SwiftData
import Combine

struct QRScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scannerViewModel = QRScannerViewModel()
    @State private var showPlayView = false
    @State private var scannedCard: Card?
    @Query private var allCards: [Card]
    
    private let baseURL = "https://api.mucajey.twicemind.com"
    @State private var isScanning = false

    // 🔥 Puls-Animation für den Border
    @State private var isBorderPulsing = false
    
    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedMeshGradient().ignoresSafeArea()
            
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack {
                ZStack(alignment: .bottomTrailing) {
                    QRCodeCameraView(viewModel: scannerViewModel)
                        .frame(width: 260, height: 260)
                    
                    // Flashlight-Button in der rechten unteren Ecke *in* der Cam-View
                    Button(action: {
                        scannerViewModel.toggleFlashlight()
                    }) {
                        Image(systemName: scannerViewModel.isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)            // gleichmäßig → Kreis!
                            .glassEffect(.clear)
                            .clipShape(Circle())    // macht ihn wirklich rund
                            .shadow(radius: 8)
                    }
                    .padding(10) // Abstand zum Rand – bleibt erhalten
                }
                .frame(width: 260, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    ZStack {
                        
                        if scannerViewModel.isScanning {
                            // ✅ Scanner aktiv → nur weißer Puls-Rahmen
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 4)
                                .shadow(color: .white.opacity(0.9), radius: 12)
                                .scaleEffect(isBorderPulsing ? 1.04 : 0.98)
                                .opacity(isBorderPulsing ? 1 : 0.25)
                                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                                           value: isBorderPulsing)
                        } else {
                            // ❗ Scanner nicht aktiv → statischer roter Rand
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red, lineWidth: 4)
                                .shadow(color: .red.opacity(0.5), radius: 10)
                                .opacity(0.8)
                        }
                    }
                )
                .frame(width: 280, height: 280)
                
                HStack(spacing: 20) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("Scanne den QR-Code...")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .pink.opacity(0.3), radius: 4)
                        .shadow(color: .cyan.opacity(0.25), radius: 6)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    .ultraThinMaterial.opacity(0.65),
                    in: Capsule()
                )
                .shadow(radius: 12, y: 6)
            }
            
            // Error Message
            if let error = scannerViewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.red.opacity(0.8))
                        )
                        .padding(.horizontal, 40)
                        .padding(.bottom, 120)
                    Spacer()
                }
            }
        }
        .onAppear {
            scannerViewModel.startScanning()
            // Puls starten
            isBorderPulsing = true
        }
        .onDisappear {
            scannerViewModel.stopScanning()
        }
        .onChange(of: scannerViewModel.scannedURL) { oldValue, newValue in
            if let url = newValue {
                processScannedURL(url)
            }
        }
        // Puls nur laufen lassen, wenn wirklich gescannt wird (optional)
        .onChange(of: scannerViewModel.isScanning) { _, newValue in
            isBorderPulsing = newValue
        }
        // 👇 ersetzt das alte onDismiss aus fullScreenCover
        .onChange(of: showPlayView) { _, isShowing in
            if !isShowing {
                // PlayView wurde geschlossen → Scanner frisch zurücksetzen
                scannerViewModel.scannedURL = nil
                scannerViewModel.errorMessage = nil
                scannerViewModel.startScanning()
            } else {
                // PlayView wird angezeigt → lieber stoppen
                scannerViewModel.stopScanning()
            }
        }
        // 👇 Navigation-Push zur PlayView (statt fullScreenCover)
        .navigationDestination(isPresented: $showPlayView) {
            if let card = scannedCard {
                PlayView(card: card)
            } else {
                EmptyView()
            }
        }
        .navigationTitle("Scanner")
        .toolbarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func processScannedURL(_ urlString: String) {
        // 1. URL normalisieren: falls kein http/https am Anfang, ergänzen wir https://
        let normalizedURLString: String
        if urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://") {
            normalizedURLString = urlString
        } else {
            normalizedURLString = "https://" + urlString
        }
        
        // 2. URL & Komponenten bauen
        guard let url = URL(string: normalizedURLString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            scannerViewModel.errorMessage = String(localized: "scanner.invalidQR")
            return
        }
        
        // Erwartete Pfade:
        // /de/00073                  -> ["de", "00073"]
        // /de/aaaa0007/00073         -> ["de", "aaaa0007", "00073"]
        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)
        
        guard pathComponents.count >= 2 else {
            scannerViewModel.errorMessage = String(localized: "scanner.invalidFormat")
            return
        }
        
        let language = pathComponents[0]   // "de"
        let edition: String
        let cardId: String
        
        if pathComponents.count == 2 {
            // Classic: /de/00073
            edition = "hitster-\(language)"                   // Classic/Basis-Edition
            cardId = pathComponents[1]
        } else if pathComponents.count == 3 {
            // Edition mit Identifier: /de/aaaa0007/00073
            edition = "hitster-\(language)-\(pathComponents[1])"
            cardId = pathComponents[2]
        } else {
            // Unerwartetes Format
            scannerViewModel.errorMessage = String(localized: "scanner.invalidFormat")
            return
        }
        
        print("📍 Scan erfolgreich")
        print("URL: \(urlString)")
        print("Edition: \(edition) | CardID: \(cardId) | Sprache: \(language)")
        
        // Weiterverarbeitung
        findCard(edition: edition, cardId: cardId, language: language)
    }
    
    func filteredCards(selectedEdition: String) -> [Card] {
        if selectedEdition == "Alle" {
            return allCards
        } else {
            var cards = allCards.filter { $0.edition == selectedEdition }
            cards.sort { $0.cardId < $1.cardId }
            return cards
        }
    }
    
    private func findCard(edition: String, cardId: String, language: String) {
        let editionCards: [Card] = filteredCards(selectedEdition: edition)
        let cardWithID: [Card] = editionCards.filter { $0.cardId == cardId }
        
        if let card = cardWithID.first {
            // If Apple Music data already present, play immediately
            if !(card.appleId).isEmpty && !(card.appleUri).isEmpty {
                scannedCard = card
                showPlayView = true
                scannerViewModel.stopScanning()
            } else {
                // Trigger mapping, then present
                scannerViewModel.isScanning = true
                Task { @MainActor in
                    await self.appleMusicMapping(card: card)
                }
            }
        } else {
            scannerViewModel.errorMessage = String(localized: "scanner.cardNotFound")
            // Nach 2 Sekunden wieder scannen
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                scannerViewModel.errorMessage = nil
                scannerViewModel.startScanning()
            }
        }
    }
    
    private func appleMusicMapping(card: Card) async {
        do {
            let mapping = try await self.triggerMapping(card: card)
            // Persist Apple Music data into the card
            if let apple = mapping.apple, let id = apple.id, let uri = apple.uri {
                card.appleId = id
                card.appleUri = uri
            } else if let cardApple = mapping.card?.apple, let id = cardApple.id, let uri = cardApple.uri {
                card.appleId = id
                card.appleUri = uri
            } else {
                // If mapping didn't provide both id and uri, report error and resume scanning
                self.scannerViewModel.errorMessage = String(localized: "scanner.mappingMissingData")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.scannerViewModel.errorMessage = nil
                    self.scannerViewModel.startScanning()
                }
                return
            }

            // Present play view with updated card
            self.scannedCard = card
            self.showPlayView = true
            self.scannerViewModel.stopScanning()
        } catch {
            let errorMsg = ErrorHandler().handleError(error)
            self.scannerViewModel.errorMessage = errorMsg
            // Resume scanning after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.scannerViewModel.errorMessage = nil
                self.scannerViewModel.startScanning()
            }
        }
    }
    
    private func triggerMapping(card: Card) async throws -> DTOModelsAPI.AppleMappingResponse {
        let data = try await APICard().map(edition: card.edition, cardID: card.cardId)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(DTOModelsAPI.AppleMappingResponse.self, from: data)
    }
}

struct CornerIndicator: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let position: Position
    
    var body: some View {
        VStack(spacing: 0) {
            if position == .topLeft || position == .topRight {
                horizontalLine
                verticalLine
            } else {
                verticalLine
                horizontalLine
            }
        }
        .frame(width: 30, height: 30)
        .rotationEffect(rotation)
    }
    
    private var horizontalLine: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 30, height: 4)
    }
    
    private var verticalLine: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 4, height: 30)
            .offset(x: position == .topLeft || position == .bottomLeft ? -13 : 13)
    }
    
    private var rotation: Angle {
        switch position {
        case .topLeft: return .degrees(0)
        case .topRight: return .degrees(0)
        case .bottomLeft: return .degrees(0)
        case .bottomRight: return .degrees(0)
        }
    }
}

@MainActor
class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedURL: String?
    @Published var errorMessage: String?
    @Published var isFlashlightOn = false
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    func startScanning() {
        // Wenn Session schon existiert → einfach wieder starten
        if let session = captureSession {
            if !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    session.startRunning()
                    DispatchQueue.main.async {
                        self?.isScanning = true
                    }
                }
            }
        } else {
            // Erster Start → Permissions + Setup
            checkPermissions()
        }
    }
    
    func stopScanning() {
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
        isScanning = false
    }
    
    func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            if isFlashlightOn {
                device.torchMode = .off
                isFlashlightOn = false
            } else {
                device.torchMode = .on
                isFlashlightOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Flashlight error: \(error)")
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCameraIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCameraIfNeeded()
                    } else {
                        self?.errorMessage = String(localized: "scanner.permissionDenied")
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = String(localized: "scanner.permissionDenied")
        @unknown default:
            errorMessage = String(localized: "scanner.unknownError")
        }
    }
    
    private func setupCameraIfNeeded() {
        // 👇 Nur einmal Session und Pipeline erzeugen
        if captureSession != nil {
            startScanning()
            return
        }
        
        let session = AVCaptureSession()
        captureSession = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = String(localized: "scanner.cameraError")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                errorMessage = String(localized: "scanner.inputError")
                return
            }
        } catch {
            errorMessage = String(localized: "scanner.cameraError")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            errorMessage = String(localized: "scanner.outputError")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                self?.isScanning = true
            }
        }
    }
    
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput metadataObjects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            Task { @MainActor in
                scannedURL = stringValue
            }
        }
    }
    
    func getCaptureSession() -> AVCaptureSession? {
        return captureSession
    }
}

// Camera Preview
struct QRCodeCameraView: UIViewRepresentable {
    let viewModel: QRScannerViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let captureSession = viewModel.getCaptureSession() {
                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = view.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.addSublayer(previewLayer)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct AnimatedGradientBorder: View {
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 32)
            .trim(from: 0, to: 1)
            .stroke(
                AngularGradient(colors: [.pink, .orange, .yellow, .green, .cyan, .purple, .pink],
                                center: .center,
                                angle: .degrees(animate ? 360 : 0)),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: animate)
            .onAppear { animate = true }
    }
}

#Preview {
    NavigationStack {
        QRScannerView()
            .modelContainer(for: [Card.self])
    }
}
