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
                    Image("back")
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: .fit)
                }
            }
            .border(Color.secondary, width: 0.25)
            .rotation3DEffect(
                .degrees(isFaceUp ? 0 : 180),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            startingY = geo.frame(in: .global).minY
                        }
                }
            )
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.1 : 1)
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    onPlay?()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        isDragging = true
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        let globalYposition = value.location.y + startingY
                        let handAreaHeight = (UIDevice.current.userInterfaceIdiom == .pad) ? 500.0 : 400.0
                        print("my current y: \(globalYposition)")
                        if globalYposition <= UIScreen.main.bounds.height - handAreaHeight {
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
