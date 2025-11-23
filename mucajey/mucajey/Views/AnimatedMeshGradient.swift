import SwiftUI

struct AnimatedMeshGradient: View {
    @State var appear1 = false
    @State var appear2 = false
    @State var appear3 = false
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [appear2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear1 ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
                [0.0, 1.0], [1.0, appear2 ? 2.0 : 1.0], [1.0, 1.0],
                [0.0, 0.0], [appear3 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
        ], colors: [
            appear2 ? .red : .orange, appear2 ? .yellow : .cyan, .orange,
            appear1 ? .blue : .red, appear1 ? .cyan : .blue, appear1 ? .red : .purple,
            appear1 ? .red : .cyan, appear1 ? .orange : .blue, appear2 ? .red : .purple,
            appear3 ? .red : .orange, appear3 ? .orange : .blue, appear1 ? .red : .blue

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
            withAnimation(
                .easeInOut(duration: 5.0)
                .repeatForever(autoreverses: true))
            {
                appear3.toggle()
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

