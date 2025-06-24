//
//  CardView.swift
//  C4 Playground
//
//  Created by Savio Enoson on 09/06/25.
//

import GameKit
import Foundation
import SwiftUI


struct CardView: View {
    let card: Card
    var onPlay: (() -> Void)? = nil
    var isFaceUp: Bool = false
    
    // Track movement with drag offset
    @State var startingY = 0.0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    private let aspectRatio: CGFloat = 2.5 / 3.5
    
    var body: some View {
        ZStack {
            ZStack {
                if isFaceUp {
                    Image(card.imageName)
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: .fit)
                } else {
                    Image("cardBack")
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: .fit)
                }
            }
            .rotation3DEffect(
                .degrees(isFaceUp ? 0 : 180),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .background(
                // Create geometry reader on appear to set start (spawn) Y position. Global offset is calculated from herez
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            startingY = geo.frame(in: .global).minY
                        }
                }
            )
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.1 : 1)
            .gesture(
                // If dragged to center, letting go of card will trigger the onPlay function for it.
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        isDragging = true
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        let globalYposition = value.location.y + startingY
                        let handAreaHeight = UIScreen.main.bounds.height * (UIDevice.current.orientation.isLandscape ? 0.5 : 0.65)
                        print("my current y: \(globalYposition)")
                        if globalYposition <= handAreaHeight {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                                onPlay?()
                            }
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static let demoCards = [
        Card(cardType: .number, value: .add_1),
        Card(cardType: .number, value: .subtract_5),
        Card(cardType: .number, value: .subtract_2),
        Card(cardType: .number, value: .add_4),
        Card(cardType: .number, value: .add_2),
        Card(cardType: .number, value: .subtract_4),
        Card(cardType: .number, value: .add_3),
        Card(cardType: .number, value: .subtract_3),
        Card(cardType: .number, value: .add_5),
        Card(cardType: .number, value: .subtract_1),
    ]
    
    static var previews: some View {
        VStack(spacing: 20) {
            // Face-up cards preview
            Text("Face Up Cards").font(.title)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                ForEach(demoCards) { card in
                    CardView(
                        card: card,
                        onPlay: {
                          print("play")
                        },
                        isFaceUp: true,
                    )
                    .frame(width: 120, height: 168)
                }
            }
            .padding()
        }
    }
}
