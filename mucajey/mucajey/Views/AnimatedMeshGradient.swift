import SwiftUI

struct AnimatedMeshGradient: View {
    @State var appear1 = false
    @State var appear2 = false
    
    private let neonPalette: [Color] = [
        Color(red: 1.00, green: 0.00, blue: 0.33), // #FF0054
        Color(red: 1.00, green: 0.55, blue: 0.00), // #FF8C00
        Color(red: 1.00, green: 0.83, blue: 0.00), // #FFD300
        Color(red: 0.00, green: 1.00, blue: 0.78), // #00FFC7
        Color(red: 0.00, green: 0.75, blue: 1.00), // #00BFFF
        Color(red: 0.75, green: 0.00, blue: 1.00), // #BF00FF
        Color(red: 1.00, green: 0.24, blue: 0.94)  // #FF3DF0
    ]
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [appear2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear1 ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
                [0.0, 1.0], [1.0, appear2 ? 2.0 : 1.0], [1.0, 1.0],
                [0.0, 0.0],
        ], colors: [
            neonPalette[0],
            appear2 ? neonPalette[3] : neonPalette[1],neonPalette[2],
            appear1 ? neonPalette[4] : neonPalette[5],
            appear1 ? neonPalette[3] : neonPalette[4],
            appear1 ? neonPalette[5] : neonPalette[6],
            appear1 ? neonPalette[5] : neonPalette[3],
            appear1 ? neonPalette[1] : neonPalette[4],
            appear2 ? neonPalette[5] : neonPalette[6],
            appear1 ? neonPalette[5] : neonPalette[4]

        ])
        .edgesIgnoringSafeArea(.all)
        .onAppear() {
            withAnimation(
                .easeInOut(duration: 5.0)
                .repeatForever(autoreverses: true))
            {
                appear1.toggle()
            }
            withAnimation(
                .easeInOut(duration: 5.0)
                .repeatForever(autoreverses: true))
            {
                appear2.toggle()
            }
        }
    }
}

#Preview {
    AnimatedMeshGradient()
        .ignoresSafeArea()
}//
//  AnimatedMeshGradient.swift
//  liquido
//
//  Created by Thomas Herfort on 13.11.25.
//

