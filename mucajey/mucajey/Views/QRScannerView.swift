import SwiftUI
import AVFoundation
import SwiftData
internal import Combine

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scannerViewModel = QRScannerViewModel()
    @State private var showPlayView = false
    @State private var scannedCard: HitsterCard?
    
    var body: some View {
        ZStack {
            // Camera Preview
            QRCodeCameraView(viewModel: scannerViewModel)
                .ignoresSafeArea()
            
            // Overlay
            VStack {
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
                        .glassEffect(.clear)
                        .padding(12)
                        /*.background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.black.opacity(0.5))
                        )*/
                    }
                    
                    Spacer()
                }
                .padding(20)
                
                Spacer()
                
                // Scanning Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(scannerViewModel.isScanning ? Color.white : Color(red: 0.91, green: 0.18, blue: 0.49), lineWidth: 3)
                        .frame(width: 280, height: 280)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    // Corner indicators
                    VStack {
                        HStack {
                            CornerIndicator(position: .topLeft)
                            Spacer()
                            CornerIndicator(position: .topRight)
                        }
                        Spacer()
                        HStack {
                            CornerIndicator(position: .bottomLeft)
                            Spacer()
                            CornerIndicator(position: .bottomRight)
                        }
                    }
                    .frame(width: 280, height: 280)
                }
                
                Spacer()
                
                // Instructions
                VStack(spacing: 16) {
                    Text(LocalizedStringKey("scanner.instruction"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if scannerViewModel.isScanning {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text(LocalizedStringKey("scanner.scanning"))
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.black.opacity(0.6))
                        )
                    }
                    
                    // Flashlight Toggle
                    Button(action: {
                        scannerViewModel.toggleFlashlight()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: scannerViewModel.isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            Text(scannerViewModel.isFlashlightOn ? LocalizedStringKey("scanner.flashlightOff") : LocalizedStringKey("scanner.flashlightOn"))
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.black.opacity(0.6))
                        )
                    }
                    
                    // TEST BUTTON - Simuliert erfolgreichen Scan
                    Button(action: {
                        simulateSuccessfulScan()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                            Text("TEST: Beispielkarte laden")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0.91, green: 0.18, blue: 0.49))
                        )
                    }
                }
                .padding(.bottom, 60)
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
        }
        .onDisappear {
            scannerViewModel.stopScanning()
        }
        .onChange(of: scannerViewModel.scannedURL) { oldValue, newValue in
            if let url = newValue {
                processScannedURL(url)
            }
        }
        .fullScreenCover(isPresented: $showPlayView) {
            if let card = scannedCard {
                PlayView(card: card)
            }
        }
    }
    
    private func processScannedURL(_ urlString: String) {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            scannerViewModel.errorMessage = String(localized: "scanner.invalidQR")
            return
        }
        
        // Parse URL: http://www.hitstergame.com/de/00001 oder http://www.hitstergame.com/de/aaaa0007/00001
        let pathComponents = components.path.split(separator: "/").map(String.init)
        
        guard pathComponents.count >= 2 else {
            scannerViewModel.errorMessage = String(localized: "scanner.invalidFormat")
            return
        }
        
        let language = pathComponents[0] // "de"
        var edition = ""
        var cardId = ""
        
        if pathComponents.count == 2 {
            // Format: /de/00001 (Basis-Edition)
            cardId = pathComponents[1]
            edition = "" // Basis-Edition hat kein Prefix
        } else if pathComponents.count == 3 {
            // Format: /de/aaaa0007/00001
            edition = pathComponents[1]
            cardId = pathComponents[2]
        } else {
            scannerViewModel.errorMessage = String(localized: "scanner.invalidFormat")
            return
        }
        
        // Suche Karte in der Datenbank
        findCard(edition: edition, cardId: cardId, language: language)
    }
    
    private func findCard(edition: String, cardId: String, language: String) {
        let predicate = #Predicate<HitsterCard> { card in
            card.cardId == cardId
        }
        
        let descriptor = FetchDescriptor<HitsterCard>(predicate: predicate)
        
        do {
            let cards = try modelContext.fetch(descriptor)
            
            // Wenn Edition angegeben, nach Edition filtern
            let filteredCards: [HitsterCard]
            if !edition.isEmpty {
                // Suche nach Edition-Identifier in der Edition-Bezeichnung
                // z.B. "aaaa0007" sollte Karten mit diesem Identifier finden
                filteredCards = cards.filter { card in
                    // Prüfe ob die Edition den identifier enthält
                    card.edition.lowercased().contains(edition.lowercased())
                }
            } else {
                // Basis-Edition (Hitster Deutschland, die Hauptedition ohne zusätzlichen Identifier)
                // Dies sind die Karten aus hitster-de.json
                filteredCards = cards.filter { card in
                    let editionLower = card.edition.lowercased()
                    // Hauptedition hat keine Suffixe wie "aaaa"
                    return editionLower.contains("hitster") && 
                           editionLower.contains("deutsch") &&
                           !editionLower.contains("aaaa")
                }
            }
            
            if let card = filteredCards.first {
                scannedCard = card
                showPlayView = true
                scannerViewModel.stopScanning()
            } else {
                scannerViewModel.errorMessage = String(localized: "scanner.cardNotFound")
                // Nach 2 Sekunden wieder scannen
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    scannerViewModel.errorMessage = nil
                    scannerViewModel.startScanning()
                }
            }
        } catch {
            scannerViewModel.errorMessage = "\(String(localized: "scanner.searchError")): \(error.localizedDescription)"
        }
    }
    
    // TEST FUNKTION - Simuliert erfolgreichen Scan einer Beispielkarte
    private func simulateSuccessfulScan() {
        scannerViewModel.stopScanning()
        
        // Suche eine Karte aus der Basis-Edition (hitster-de) mit Apple Music ID
        let predicate = #Predicate<HitsterCard> { card in
            !card.appleId.isEmpty
        }
        
        let descriptor = FetchDescriptor<HitsterCard>(predicate: predicate)
        
        do {
            let cards = try modelContext.fetch(descriptor)
            
            // Filter auf Basis-Edition
            let baseEditionCards = cards.filter { card in
                let editionLower = card.edition.lowercased()
                return editionLower.contains("hitster") && 
                       editionLower.contains("deutsch") &&
                       !editionLower.contains("aaaa")
            }
            
            if let testCard = baseEditionCards.first {
                scannedCard = testCard
                showPlayView = true
            } else {
                scannerViewModel.errorMessage = "TEST: Keine Karte mit Apple Music ID gefunden"
            }
        } catch {
            scannerViewModel.errorMessage = "TEST: Fehler beim Laden der Testkarte"
        }
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

// QR Code Scanner ViewModel
@MainActor
class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedURL: String?
    @Published var errorMessage: String?
    @Published var isFlashlightOn = false
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    func startScanning() {
        checkPermissions()
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
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
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
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
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession,
              let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = String(localized: "scanner.cameraError")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            errorMessage = String(localized: "scanner.cameraError")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            errorMessage = String(localized: "scanner.inputError")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            errorMessage = String(localized: "scanner.outputError")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isScanning = true
            }
        }
    }
    
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
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

#Preview {
    QRScannerView()
        .modelContainer(for: [HitsterCard.self])
}
