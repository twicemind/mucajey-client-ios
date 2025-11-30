//
//  ScannerView.swift
//  mucajey
//
//  Created by Thomas Herfort on 27.11.25.
//

import SwiftUI
import SwiftData
import Combine
@preconcurrency import AVFoundation

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scannerViewModel = QRScannerModel()
    
    var body: some View {
        ZStack {
            // Camera Preview
            QRCodeCamView(viewModel: scannerViewModel)
                .ignoresSafeArea()
            NavigationStack {
                // Scanning Frame
                Spacer()
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
            }
            .background(Color.black)
        }
    }
}

struct CornerIndication: View {
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
class QRScannerModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
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
struct QRCodeCamView: UIViewRepresentable {
    let viewModel: QRScannerModel
    
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
    ScannerView()
}
