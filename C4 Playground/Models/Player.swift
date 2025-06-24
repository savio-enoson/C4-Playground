//
//  Untitled.swift
//  C4 Playground
//
//  Created by Gerald Gavin Lienardi on 23/06/25.
//
import Foundation
import GameKit
import SwiftUI

class Player {
//    GameKit
    var gameKit: GKPlayer
    var profilePicture: Image? = nil
    
//    In-game variables
    var hand: [Card] = []
    var isBusted: Bool = false
    
//    Status Effects
    var isBananad: Bool = false

    init(gameKit: GKPlayer) {
        self.gameKit = gameKit
        loadProfilePicture()
    }

    func loadProfilePicture() {
        gameKit.loadPhoto(for: .small) { [weak self] uiImage, error in
            if let uiImage {
                self?.profilePicture = Image(uiImage: uiImage)
            } else if let error {
                print("❌ Failed to load profile picture: \(error.localizedDescription)")
            }
        }
    }
    
    func reset(){
        isBusted = false
        hand = []
        isBananad = false
    }
    
//    Default game functions
    func addToHand(_ card: Card){
        hand.append(card)
    }
    
    func playCard(_ card: Card) {
        if let index = hand.firstIndex(of: card) {
            hand.remove(at: index)
        } else {
            print("⚠️ Tried to play a card not in hand.")
        }
    }
    
    func busted(){
        isBusted = true
    }
    
//    Status effects
    func getBananad(){
        isBananad = true
    }

    func endTurn(){
        if isBananad{
            isBananad = false
        }
    }
}

