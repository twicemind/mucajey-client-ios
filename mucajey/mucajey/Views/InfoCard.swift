//
//  InfoCard.swift
//  TuneQuest
//
//  Created by Thomas Herfort on 19.11.25.
//

import SwiftUI

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(width: 100,height: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.91, green: 0.18, blue: 0.49),
                    Color(red: 0.49, green: 0.11, blue: 0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(
                RoundedRectangle(cornerRadius: 15)
            )
        }
    }
}
