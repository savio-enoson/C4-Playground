//
//  GameView.swift
//  C4 Playground
//
//  Created by Savio Enoson on 13/06/25.
//

import SwiftUI
import GameKit

//var countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

struct GameView: View {
    let isiPad: Bool = (UIDevice.current.userInterfaceIdiom == .pad);
    let columns: Int = (UIDevice.current.userInterfaceIdiom == .pad) ? 5 : 3
    let cardWidth: Double = (UIDevice.current.userInterfaceIdiom == .pad) ? 300.0 : 200.0
    
    @State private var showDropArea = false
    @State private var dropAreaSize: CGSize = .init(width: (UIDevice.current.userInterfaceIdiom == .pad) ? 400.0 : 300.0, height: (UIDevice.current.userInterfaceIdiom == .pad) ? 300.0 : 200.0)
    
    @ObservedObject var game: CardGame
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
            
            if game.inGame {
                ZStack {
                    ZStack {
                        PlayersContainer(players: game.players, playerProfileImages: game.playerProfileImages, playerHands: game.playerHands, myIndex: game.localPlayerIndex)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Text("TALLY \n\(game.tally)")
                            .font(isiPad ? .title3 : .body)
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(radius: 2)
                            )
                            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - cardWidth * 1.15)
                    }
                    .zIndex(.infinity)
                    
                    VStack {
                        Spacer()
                        
                        discardPile
                            .padding(.top, isiPad ? 200 : 100)
                        
                        HStack {
                            cardDeck
                                .padding(.leading, 60)
                            Spacer()
                        }
                        
                        Spacer()
                        
                        if game.whoseTurn == game.localPlayerIndex {
                            if isiPad {
                                playerHand
                                    .padding()
                            } else {
                                if game.playerHands[game.localPlayerIndex].count > 0 {
                                    mobilePlayerHand
                                        .padding()
                                }
                            }
                        }
                    }
                }
                //  When all players have received the deck, the game can start. This time we use the game.players variable because it is faster than checking the match variable again. However, this means we need to start from 1 because game.players includes the local player.
                //  TODO: Double click the startGame function and jump to definition.
                .onChange(of: game.playersReceivedDeck, {
                    if game.playersReceivedDeck == game.players.count {
                        game.startGame()
                    }
                })
                .onChange(of: game.playersReceivedReshuffleCMD, {
                    if game.playersReceivedReshuffleCMD == game.players.count {
                        game.finishTurn()
                        game.playersReceivedReshuffleCMD = 1
                    }
                })
                .alert("You Busted! 😜", isPresented: $game.playerIsEliminated[game.localPlayerIndex]) {
                    Button("I Concede 😔") {
                        game.inGame = false
                    }
                } message: {
                    Text("Uh, oh, the tally has gone over \(game.maxTally)!")
                }
                .alert("You Won!", isPresented: $game.localPlayerWon) {
                    Button("Hurray 🎉! ") {
                        game.inGame = false
                    }
                } message: {
                    Text("You are the last player standing, way to go!")
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var cardDeck: some View {
        let frameWidth = isiPad ? 100.0 : 60.0
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
            ForEach(Array(game.playerHands[game.localPlayerIndex].enumerated()), id: \.element.id) { index, card in
                CardView(card: card, onPlay: {game.playCard(playedCard: card, indexInHand: index)}, isFaceUp: true)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }
    
    var mobilePlayerHand: some View {
        // Use binding or observed object to track changes in game.playerHands
        let numCards = game.playerHands[game.localPlayerIndex].count
        let smallerCardSize = cardWidth * 0.67
        
        return VStack(spacing: -90) {
            // Bottom row (3 cards - appears visually on top)
            HStack(spacing: -15) {
                ForEach(0..<3, id: \.self) { index in
                    let currentCard = game.playerHands[game.localPlayerIndex][index]
                    CardView(card: currentCard, onPlay: { game.playCard(playedCard: currentCard, indexInHand: index) }, isFaceUp: true)
                        .frame(width: smallerCardSize)
                        .zIndex(Double(index))
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            
            // Top row (remaining cards - appears underneath)
            HStack(spacing: -15) {
                ForEach(3..<numCards, id: \.self) { index in
                    let currentCard = game.playerHands[game.localPlayerIndex][index]
                    CardView(card: currentCard, onPlay: { game.playCard(playedCard: currentCard, indexInHand: index) }, isFaceUp: true)
                        .frame(width: smallerCardSize)
                        .zIndex(Double(index))
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var discardPile: some View {
        return ZStack {
            if game.whoseTurn == game.localPlayerIndex {
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

//#Preview {
//    GameView(game: CardGame())
//}
