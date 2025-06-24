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
    let isiPad: Bool = (UIDevice.current.userInterfaceIdiom == .pad);
    let players: [GKPlayer]
    let playerProfileImages: [Image]
    let playerHands: [[Card]]
    let myIndex: Int
    let playerYoffset = -120.0
    
    var body: some View {
        let playerCount = players.count - 1
        let playersExcludingMe = Array(0...playerCount).filter({ $0 != myIndex})
        
        GeometryReader { geometry in
            ZStack {
                switch playerCount {
                case 1:
                    ZStack {
                        otherPlayerHand(playerCards: playerHands[playersExcludingMe[0]], cardRotation: 0.0)
                            .position(x: geometry.size.width / 2, y: 40)
                        
                        PlayerProfile(playerName: players[playersExcludingMe[0]].displayName,
                                      image: playerProfileImages[playersExcludingMe[0]],
                                      color: .blue)
                        .position(x: geometry.size.width / 2, y: isiPad ? 50 : 75)
                    }
                case 2:
                    HStack {
                        ZStack {
                            otherPlayerHand(playerCards: playerHands[playersExcludingMe[0]], cardRotation: 90.0)
                            
                            PlayerProfile(playerName: players[playersExcludingMe[0]].displayName,
                                          image: playerProfileImages[playersExcludingMe[0]],
                                          color: .red).offset(x: 0, y: isiPad ? playerYoffset * 1.5 : playerYoffset)
                        }
                        
                        Spacer()
                        
                        ZStack  {
                            otherPlayerHand(playerCards: playerHands[playersExcludingMe[1]], cardRotation: 90.0)
                            
                            PlayerProfile(playerName: players[playersExcludingMe[1]].displayName,
                                          image: playerProfileImages[playersExcludingMe[1]],
                                          color: .green).offset(x: 0, y: isiPad ? playerYoffset * 1.5 : playerYoffset)
                        }
                    }
                    .position(x: geometry.size.width/2, y: geometry.size.height/3)
                case 3:
                    ZStack {
                        otherPlayerHand(playerCards: playerHands[playersExcludingMe[0]], cardRotation: 0.0)
                            .position(x: geometry.size.width / 2, y: 40)
                        
                        PlayerProfile(playerName: players[playersExcludingMe[0]].displayName,
                                      image: playerProfileImages[playersExcludingMe[0]],
                                      color: .blue)
                        .position(x: geometry.size.width / 2, y: isiPad ? 50 : 75)
                        
                        HStack {
                            ZStack {
                                otherPlayerHand(playerCards: playerHands[playersExcludingMe[1]], cardRotation: 90.0)
                                
                                PlayerProfile(playerName: players[playersExcludingMe[1]].displayName,
                                              image: playerProfileImages[playersExcludingMe[1]],
                                              color: .red).offset(x: 0, y: isiPad ? playerYoffset * 1.5 : playerYoffset)
                            }
                            
                            Spacer()
                            
                            ZStack  {
                                otherPlayerHand(playerCards: playerHands[playersExcludingMe[2]], cardRotation: 90.0)
                                
                                PlayerProfile(playerName: players[playersExcludingMe[2]].displayName,
                                              image: playerProfileImages[playersExcludingMe[2]],
                                              color: .green).offset(x: 0, y: isiPad ? playerYoffset * 1.5 : playerYoffset)
                            }
                        }
                        .position(x: geometry.size.width/2, y: geometry.size.height/3)
                    }
                default:
                    ZStack {
                        Text("no players")
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    struct otherPlayerHand: View {
        let isiPad: Bool = (UIDevice.current.userInterfaceIdiom == .pad);
        let playerCards: [Card]
        var cardRotation: Double
        
        var body: some View {
            if cardRotation > 0.0 {
                VStack(spacing: -100) {
                    ForEach(playerCards) { card in
                        CardView(card: card,
                         onPlay: {
//                            print("played \(card.imageName)")
                        })
                        .frame(maxWidth: isiPad ? 100 : 60)
                        .rotationEffect(.degrees(cardRotation))
                    }
                }
            } else {
                HStack(spacing: -40) {
                    ForEach(playerCards) { card in
                        CardView(card: card, onPlay: {
//                            print("played \(card.imageName)")
                        })
                        .frame(maxWidth: isiPad ? 100 : 60)
                        .rotationEffect(.degrees(cardRotation))
                    }
                }
            }
        }
    }
}
