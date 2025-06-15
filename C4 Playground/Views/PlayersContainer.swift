//
//  PlayersContainer.swift
//  C4 Playground
//
//  Created by Savio Enoson on 13/06/25.
//

import Foundation
import SwiftUI
import GameKit


struct PlayersContainer: View {
    let players: [GKPlayer]
    let playerProfileImages: [Image]
    let playerHands: [[Card]]
    let myIndex: Int
    
    var body: some View {
        let edgePadding = 80.0
        let playerCount = players.count - 1
        let playersExcludingMe = Array(0...playerCount).filter({ $0 != myIndex})

        GeometryReader { geometry in
            ZStack {
                // Single player (top center)
                if playerCount == 1 {
                    ZStack {
                        otherPlayerHand(playerCards: playerHands[playersExcludingMe[0]], cardRotation: 0.0)
                            .position(x: geometry.size.width / 2, y: edgePadding)
                        
                        PlayerProfile(playerName: players[playersExcludingMe[0]].displayName,
                                      image: playerProfileImages[playersExcludingMe[0]],
                                      color: .blue)
                            .position(x: geometry.size.width / 2, y: edgePadding)
                    }
                }
                
                // Two players (left and right)
                if playerCount == 2 {
                    HStack {
                        ZStack {
                            otherPlayerHand(playerCards: playerHands[playersExcludingMe[0]], cardRotation: 90.0)
                                .position(x: 0, y: geometry.size.height * 0.4)
                            
                            PlayerProfile(playerName: players[playersExcludingMe[0]].displayName,
                                          image: playerProfileImages[playersExcludingMe[0]],
                                          color: .red)
                                .position(x: edgePadding, y: geometry.size.height * 0.25)
                        }
                        
                        ZStack  {
                            otherPlayerHand(playerCards: playerHands[playersExcludingMe[1]], cardRotation: 90.0)
                                .position(x: geometry.size.width, y: geometry.size.height * 0.4)
                            
                            PlayerProfile(playerName: players[playersExcludingMe[1]].displayName,
                                          image: playerProfileImages[playersExcludingMe[1]],
                                          color: .green)
                                .position(x: geometry.size.width - edgePadding, y: geometry.size.height * 0.25)
                        }
                    }
                    .padding(.top, geometry.size.height * 0.1)
                }
                
                // Three players (triangular formation)
                if playerCount == 3 {
                    ZStack {
                        otherPlayerHand(playerCards: playerHands[playersExcludingMe[0]], cardRotation: 0.0)
                            .position(x: geometry.size.width / 2, y: edgePadding)
                        
                        PlayerProfile(playerName: players[playersExcludingMe[0]].displayName,
                                      image: playerProfileImages[playersExcludingMe[0]],
                                      color: .blue)
                            .position(x: geometry.size.width / 2, y: edgePadding)
                    }
                    
                    ZStack {
                        otherPlayerHand(playerCards: playerHands[playersExcludingMe[1]], cardRotation: 90.0)
                            .position(x: 0, y: geometry.size.height * 0.4)
                        
                        PlayerProfile(playerName: players[playersExcludingMe[1]].displayName,
                                      image: playerProfileImages[playersExcludingMe[1]],
                                      color: .red)
                            .position(x: edgePadding, y: geometry.size.height * 0.25)
                    }
                    
                    ZStack  {
                        otherPlayerHand(playerCards: playerHands[playersExcludingMe[2]], cardRotation: 90.0)
                            .position(x: geometry.size.width, y: geometry.size.height * 0.4)
                        
                        PlayerProfile(playerName: players[playersExcludingMe[2]].displayName,
                                      image: playerProfileImages[playersExcludingMe[2]],
                                      color: .green)
                            .position(x: geometry.size.width - edgePadding, y: geometry.size.height * 0.25)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    struct otherPlayerHand: View {
        let playerCards: [Card]
        var cardRotation: Double
        
        var body: some View {
            if cardRotation > 0.0 {
                VStack(spacing: -100) {
                    ForEach(playerCards) { card in
                        CardView(card: card, onPlay: {
                            print("played \(card.imageName)")
                        })
                        .frame(maxWidth: 100)
                        .rotationEffect(.degrees(cardRotation))
                    }
                }
                .frame(maxHeight: 300)
            } else {
                HStack(spacing: -40) {
                    ForEach(playerCards) { card in
                        CardView(card: card, onPlay: {
                            print("played \(card.imageName)")
                        })
                        .frame(maxWidth: 100)
                        .rotationEffect(.degrees(cardRotation))
                    }
                }
                .frame(maxWidth: 300)
            }
        }
    }
}
