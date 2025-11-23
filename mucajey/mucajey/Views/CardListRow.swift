//
//  CardListRow.swift
//  TuneQuest
//
//  Created by Thomas Herfort on 19.11.25.
//

import SwiftUI

struct CardListRow: View {
    let card: HitsterCard
    let sortOption: SortOptionFilter
    @State private var isExpanded = false
    @State private var showPlayView = false
    
    private var badgeTopText: String {
        switch sortOption {
        case .year:
            return "Jahr"
        case .cardId:
            return "ID"
        case .artist:
            return "Jahr"
        case .title:
            return "Jahr"
        case .edition:
            return "Jahr"
        }
    }
    
    private var badgeBottomText: String {
        switch sortOption {
        case .year:
            return card.year
        case .cardId:
            return card.cardId
        case .artist, .title:
            return card.year
        case .edition:
            return card.year
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Badge based on sort option
                    VStack(spacing: 2) {
                        Text(badgeTopText)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.91, green: 0.18, blue: 0.49))
                        
                        Text(badgeBottomText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.91, green: 0.18, blue: 0.49))
                    }
                    .frame(width: 50)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(card.artist)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play Button
                    if !card.appleId.isEmpty || !card.spotifyId.isEmpty {
                        Button(action: {
                            showPlayView = true
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("ID: \(card.cardId)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            } icon: {
                                Image(systemName: "number")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Label {
                                Text(card.edition)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            } icon: {
                                Image(systemName: "square.stack.3d.up")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if !card.appleUri.isEmpty {
                                Label {
                                    Text("Apple Music")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                } icon: {
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            if !card.spotifyUri.isEmpty {
                                Label {
                                    Text("Spotify")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                } icon: {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background {
            if #available(iOS 18.0, *) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(isExpanded ? .regularMaterial : .thinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(isExpanded ? .white.opacity(0.15) : .white.opacity(0.05))
            }
        }
        .fullScreenCover(isPresented: $showPlayView) {
            PlayView(card: card)
        }
    }
}
