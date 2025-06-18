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
            // Use GameKit's built-in host selection
            match.chooseBestHostingPlayer { [weak self] (selectedPlayer) in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    let allPlayers = [GKLocalPlayer.local] + match.players
//                    print("All players connected. Order:")
//                    allPlayers.forEach { print($0.displayName) }
                    
                    // Validate we have players
                    guard !allPlayers.isEmpty else {
                        print("No players available")
                        return
                    }
                    
                    let finalHost = selectedPlayer ?? allPlayers.min(by: { $0.displayName < $1.displayName }) ?? GKLocalPlayer.local
                    print("Starting game with host: \(finalHost.displayName)")
                    
                    self.host = finalHost
                    self.setupGame(newMatch: match, host: finalHost)
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
