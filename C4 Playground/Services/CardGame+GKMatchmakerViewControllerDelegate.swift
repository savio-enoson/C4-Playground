//
//  CardGame+GKTurnBasedMatchmakerViewControllerDelegate.swift
//  C4 Playground
//
//  Created by Savio Enoson on 13/06/25.
//

import Foundation
import GameKit
import SwiftUI

extension CardGame: GKMatchmakerViewControllerDelegate {
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        // If all players connected, start the game
        if match.expectedPlayerCount == 0 {
            // First get all players including local player
            let allPlayers = [GKLocalPlayer.local] + match.players
            print("All players connected. Order:")
            match.players.forEach { print($0.displayName) }
            
            // Use GameKit's built-in host selection
            match.chooseBestHostingPlayer { [weak self] (selectedPlayer) in
                guard let self = self else { return }
                
                if let selectedPlayer = selectedPlayer {
                    print("Selected host: \(selectedPlayer.displayName)")
                    
                    // Start game with the selected host
                    self.host = selectedPlayer
                    self.startGame(newMatch: match, host: selectedPlayer)
                } else {
                    // Fallback if selection fails
                    print("Host selection failed, using fallback")
                    let fallbackHost = allPlayers.min(by: { $0.displayName < $1.displayName })!
                    self.host = fallbackHost
                    self.startGame(newMatch: match, host: fallbackHost)
                }
            }
        }
    }
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: any Error) {
        viewController.dismiss(animated: true)
        print("\n\nMatchmaker view controller fails with error: \(error.localizedDescription)")
    }
}
