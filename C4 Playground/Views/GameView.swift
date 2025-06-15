//
//  GameView.swift
//  C4 Playground
//
//  Created by Savio Enoson on 13/06/25.
//

import SwiftUI

var countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

struct GameView: View {
    let isiPad: Bool = (UIDevice.current.userInterfaceIdiom == .pad);
    let columns: Int = (UIDevice.current.userInterfaceIdiom == .pad) ? 5 : 3
    let cardWidth: Double = (UIDevice.current.userInterfaceIdiom == .pad) ? 300.0 : 200.0
    
    @State private var showDropArea = false
    @State private var dropAreaSize: CGSize = .init(width: (UIDevice.current.userInterfaceIdiom == .pad) ? 400.0 : 300.0, height: (UIDevice.current.userInterfaceIdiom == .pad) ? 300.0 : 200.0)

    @ObservedObject var game: CardGame
    @State private var dealButtonDisabled = false
    
    var body: some View {
        ZStack {
            ZStack {
                PlayersContainer(players: game.players, playerProfileImages: game.playerProfileImages, playerHands: game.playerHands, myIndex: game.localPlayerIndex!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Text("TALLY \n\(game.tally)")
                    .font(isiPad ? .title : .title3)
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(radius: 2)
                    )
                    .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - cardWidth * 1.5)
            }
            .zIndex(.infinity)
            
            VStack {
                Spacer()
                
                discardPile
                    .padding(.top, isiPad ? 200 : 100)
                
                HStack {
                    cardDeck
                        .padding(.leading, 100)
                        .padding(.bottom, 20)
                    Spacer()
                }

                Spacer()

                if game.whoseTurn == game.localPlayerIndex {
                    playerHand
                        .padding()
                }
            }
        }
        .background(
            Image("background")
                .resizable()
        )
        .edgesIgnoringSafeArea(.all)
//        .onReceive(countdownTimer) { _ in
//            guard game.isTimeKeeper else { return }
//            game.remainingTime -= 1
//        }
    }
    
    var cardDeck: some View {
        let frameWidth = isiPad ? 150.0 : 75.0
        let cardOffset = -0.75
        return ZStack {
            ForEach(0..<min(game.deck.count, 10), id: \.self) { index in
                CardView(card: game.deck[index])
                    .frame(minWidth: frameWidth, maxWidth: frameWidth)
                    .offset(x: CGFloat(index) * cardOffset, y: CGFloat(index) * cardOffset)
                    .zIndex(Double(-index))
            }
        }
    }
    
    var playerHand: some View {
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(Array(game.playerHands[game.localPlayerIndex!].enumerated()), id: \.element.id) { index, card in
                CardView(card: card, onPlay: {game.playNumberCard(playedCard: card)}, isFaceUp: true)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
    }
    
    var discardPile: some View {
        return ZStack {
            if !game.playerHands[game.localPlayerIndex!].isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.blue, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
                    .frame(width: dropAreaSize.width, height: dropAreaSize.height)
                    .transition(.scale)
            }
            
            ForEach(Array(game.discardPile.enumerated()), id: \.element.id) { (index, card) in
                CardView(card: card, isFaceUp: true)
                    .frame(width: cardWidth)
                    .offset(
                        x: card.discardOffset?.x ?? CGFloat(index) * 1.5,
                        y: card.discardOffset?.y ?? CGFloat(index) * -1.5
                    )
                    .rotationEffect(.degrees(
                        card.discardRotation ?? Double(index) * 5
                    ))
                    .zIndex(Double(index))
                    .onAppear {
                        if card.discardOffset == nil {
                            game.setDiscardPosition(for: card.id, index: index)
                        }
                    }
            }
        }
        .frame(width: dropAreaSize.width, height: dropAreaSize.height)
    }
}

#Preview {
    GameView(game: CardGame())
}
