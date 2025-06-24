//
//  GameViewComponents.swift
//  C4 Playground
//
//  Created by Savio Enoson on 24/06/25.
//

import SwiftUI
import GameKit
import AudioToolbox


let isiPad: Bool = (UIDevice.current.userInterfaceIdiom == .pad);
let cardWidth: Double = isiPad ? 300.0 : 200.0


struct GameTally: View {
    @ObservedObject var game: CardGame
    let values = Array(-21...21).reversed()
    
    // Animation state
    @State private var displayedTally: Int = 0
    @State private var targetTally: Int = 0
    @State private var animationTask: Task<Void, Never>?
    
    // Feedback
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    private let stepDuration = 0.08 // Time between steps
    
    var body: some View {
        VStack(spacing: -10) {
            Text("TALLY")
                .bold()
                .font(.cTitle)
                .foregroundColor(.red)
            
            Spacer()
            
            Picker("Value", selection: $displayedTally) {
                ForEach(values, id: \.self) { value in
                    Text("\(value)")
                        .font(.cTitle)
                        .foregroundColor(.black)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .disabled(true)
            .onChange(of: game.tally) { _, newTarget in
                animateToTarget(newTarget)
            }
        }
        .padding(.vertical, 5)
        .background(
            Image("tally_box")
                .resizable()
        )
        .frame(width: 100, height: 130)
        .onAppear {
            displayedTally = game.tally
            targetTally = game.tally
        }
    }
    
    private func animateToTarget(_ target: Int) {
        animationTask?.cancel() // Cancel any ongoing animation
        
        let steps = target - displayedTally
        guard steps != 0 else { return }
        
        feedbackGenerator.prepare()
        
        animationTask = Task {
            let direction = steps > 0 ? 1 : -1
            var stepsRemaining = abs(steps)
            
            while stepsRemaining > 0 && !Task.isCancelled {
                // Update displayed value
                displayedTally += direction
                stepsRemaining -= 1
                
                // Play feedback for each step
                feedbackGenerator.selectionChanged()
                AudioServicesPlaySystemSound(1104)
                
                // Control animation speed
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_500_000_000))
            }
            
            // Ensure we land exactly on target
            if !Task.isCancelled {
                displayedTally = target
            }
        }
    }
}

struct CardDeckView: View {
    @ObservedObject var game: CardGame
    let frameWidth = isiPad ? 100.0 : 60.0
    let cardOffset = -0.75
    
    var body: some View {
        ZStack {
            ForEach(0..<min(game.deck.count, 10), id: \.self) { index in
                CardView(card: game.deck[index])
                    .frame(width: frameWidth)
                    .offset(x: CGFloat(index) * cardOffset, y: CGFloat(index) * cardOffset)
                    .zIndex(Double(-index))
            }
        }
    }
}

struct DiscardPileView: View {
    @ObservedObject var game: CardGame
    let dropAreaSize = CGSize(width: isiPad ? 400.0 : 300.0, height: isiPad ? 300.0 : 200.0)
    
    var body: some View {
        ZStack {
            if game.whoseTurn == game.localPlayerIndex {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.orange, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.15)))
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

struct PlayerHandView: View {
    @ObservedObject var game: CardGame
    @State private var highlightedCard: Card? = nil
    let columns: Int = isiPad ? 5 : 3
    let maxCardWidth = isiPad ? 150.0 : 100.0
    let maxBodyWidth = isiPad ? 750.0 : UIScreen.main.bounds.width
    
    var body: some View {
        if isiPad || UIDevice.current.orientation.isLandscape {
            largePlayerHand
        } else {
            smallPlayerHand
        }
    }
    
    var largePlayerHand: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(Array(game.playerHands[game.localPlayerIndex].enumerated()), id: \.element.id) { index, card in
                CardView(
                    card: card,
                    onPlay: { game.playCard(playedCard: card, indexInHand: index) },
                    isFaceUp: true
                )
                .frame(maxWidth: maxCardWidth)
                .scaleEffect(highlightedCard?.id == card.id ? 1.1 : 1.0)
                .offset(y: highlightedCard?.id == card.id ? -20 : 0)
                .zIndex(highlightedCard?.id == card.id ? 1 : 0)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .onTapGesture {
                    handleCardTap(card: card, index: index)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: highlightedCard)
            }
        }
        .padding()
        .frame(maxWidth: maxBodyWidth)
    }
    
    var smallPlayerHand: some View {
        let numCards = game.playerHands[game.localPlayerIndex].count
        let smallerCardSize = cardWidth * 0.5
        
        return VStack(spacing: -40) {
            if numCards >= 4 {
                // Bottom row (3 cards - appears visually on top)
                HStack {
                    ForEach(0..<3, id: \.self) { index in
                        let currentCard = game.playerHands[game.localPlayerIndex][index]
                        CardView(
                            card: currentCard,
                            onPlay: { game.playCard(playedCard: currentCard, indexInHand: index) },
                            isFaceUp: true
                        )
                        .frame(width: smallerCardSize)
                        .scaleEffect(highlightedCard?.id == currentCard.id ? 1.1 : 1.0)
                        .offset(y: highlightedCard?.id == currentCard.id ? -20 : 0)
                        .zIndex(highlightedCard?.id == currentCard.id ? Double(index) + 100 : Double(index))
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .onTapGesture {
                            handleCardTap(card: currentCard, index: index)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: highlightedCard)
                    }
                }
                
                // Top row (remaining cards - appears underneath)
                HStack {
                    ForEach(3..<numCards, id: \.self) { index in
                        let currentCard = game.playerHands[game.localPlayerIndex][index]
                        CardView(
                            card: currentCard,
                            onPlay: { game.playCard(playedCard: currentCard, indexInHand: index) },
                            isFaceUp: true
                        )
                        .frame(width: smallerCardSize)
                        .scaleEffect(highlightedCard?.id == currentCard.id ? 1.1 : 1.0)
                        .offset(y: highlightedCard?.id == currentCard.id ? -20 : 0)
                        .zIndex(highlightedCard?.id == currentCard.id ? Double(index) + 100 : Double(index))
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .onTapGesture {
                            handleCardTap(card: currentCard, index: index)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: highlightedCard)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func handleCardTap(card: Card, index: Int) {
        if highlightedCard?.id == card.id {
            // Card is already highlighted - play it
            game.playCard(playedCard: card, indexInHand: index)
            highlightedCard = nil
        } else {
            // Card is not highlighted - highlight it
            highlightedCard = card
        }
    }
}
