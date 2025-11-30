//
//  CardDetailView.swift
//  TuneQuest
//
//  Created by Thomas Herfort on 21.11.25.
//

import SwiftUI
import UIKit

struct CardDetailView: View {
    let card: Card
    @State private var showBack = false
    @Environment(\.openURL) private var openURL

    private var playableURL: URL? {
        if !card.appleUri.isEmpty, let url = URL(string: card.appleUri) { return url }
        if !card.spotifyUri.isEmpty, let url = URL(string: card.spotifyUri) { return url }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    // Background switches depending on side
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(showBack ?
                              LinearGradient(colors: [Color.purple.opacity(0.95), Color.black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [Color.pink.opacity(0.9), Color.purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .shadow(radius: 8)

                    // Front and back stacked, with 3D flip
                    cardFront
                        .opacity(showBack ? 0.0 : 1.0)
                        .rotation3DEffect(.degrees(showBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    cardBack
                        .opacity(showBack ? 1.0 : 0.0)
                        .rotation3DEffect(.degrees(showBack ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                }
                .padding(.horizontal)
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                        showBack.toggle()
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)

                    HStack(spacing: 12) {
                        if !card.appleUri.isEmpty {
                            NavigationLink {
                                PlayView(appleUri: card.appleUri, spotifyUri: nil)
                            } label: {
                                Label("Apple Music", systemImage: "applelogo")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        if !card.spotifyUri.isEmpty {
                            NavigationLink {
                                PlayView(appleUri: nil, spotifyUri: card.spotifyUri)
                            } label: {
                                Label("Spotify", systemImage: "play.circle.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }

                    Group {
                        detailRow(title: "Künstler", value: card.artist)
                        detailRow(title: "Titel", value: card.title)
                        detailRow(title: "Jahr", value: card.year)
                        detailRow(title: "Edition", value: card.edition)
                        detailRow(title: "Sprache (kurz)", value: card.languageShort)
                        detailRow(title: "Sprache (lang)", value: card.languageLong)
                        detailRow(title: "Apple ID", value: card.appleId)
                        detailRow(title: "Apple URI", value: card.appleUri)
                        detailRow(title: "Spotify ID", value: card.spotifyId)
                        detailRow(title: "Spotify URI", value: card.spotifyUri)
                        detailRow(title: "Karten-ID", value: card.cardId)
                        detailRow(title: "Zuletzt aktualisiert", value: formattedDate(card.lastUpdated))
                    }
                }
                .padding(.horizontal)
                //.opacity(1.0)
            }
            .opacity(1.0)
            .padding(.vertical)
        }
        .background(AnimatedMeshGradient()
            .ignoresSafeArea(edges: .all))
        .navigationTitle("Karte")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var cardFront: some View {
        VStack(spacing: 12) {
            Text(card.artist)
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal)

            Spacer()

            Text(card.year)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)

            Text(card.title)
                .font(.title3.weight(.medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal)

            Spacer(minLength: 8)
        }
        .frame(height: 220)
    }

    @ViewBuilder
    private var cardBack: some View {
        ZStack {
            VStack {
                Spacer()
                if let image = generateQRCodeImage() {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Text("Kein QR-Code verfügbar")
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
            }
        }
        .frame(height: 220)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func generateQRCodeImage() -> UIImage? {
        let dataString: String = !card.appleUri.isEmpty ? card.appleUri : "\(card.artist) - \(card.title)"
        guard let data = dataString.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        let context = CIContext()
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
