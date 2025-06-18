//
//  CardGame.swift
//  C4 Playground
//
//  Created by Savio Enoson on 09/06/25.
//
import Foundation
import SwiftUI
import GameKit


class CardGame: NSObject, ObservableObject {
//  Gameplay Variables
    @Published var inGame: Bool = false
    @Published var deck: [Card] = []
    @Published var tally: Int = 0
    @Published var discardPile: [Card] = []
    
//  TBD: Timer Logic
    @Published var isTimeKeeper = false
    @Published var remainingTime = 60
    
//  Player-Related Gameplay Variables
    var players: [GKPlayer] = []
    @Published var whoseTurn: Int = 0
    @Published var playerHands: [[Card]] = []
    var playerProfileImages: [Image] = []
    var playerIsEliminated: [Bool] = []
    var hasPlayed = false
    var localPlayerWon = false
    var playersReady = 1
    
//  GK Variables
    var match: GKMatch?
    var host = GKPlayer()
    var localPlayer = GKLocalPlayer.local
    var localPlayerIndex: Int = 0
    
    func createDeck() {
        deck = []
        for suit in CardSuit.allCases {
            for value in CardValue.allCases {
                deck.append(Card(cardType: .number, value: value, suit: suit))
            }
        }
        deck.shuffle()
        
        // Send shuffled deck to sync between all players
        do {
            let data = encode(message: "init", listOfCards: deck)
            try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
    
    func resetGame() {
        // Gameplay Variables
        deck = []
        tally = 0
        discardPile = []
        
        // Player-Related Gameplay Variables
        whoseTurn = 0
        players = []
        playerHands = []
        playerIsEliminated = []
        playerProfileImages = []
        hasPlayed = false
        localPlayerWon = false
        playersReady = 1
        
        // GK Variables
        match?.disconnect()
        match?.delegate = nil
    }
    
    func setDiscardPosition(for cardId: UUID, index: Int) {
        if let cardIndex = discardPile.firstIndex(where: { $0.id == cardId }) {
            discardPile[cardIndex].setDiscardPosition(index: index)
        }
    }
    
    var rootViewController: UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }
    
    func authenticatePlayer() {
        // Set the authentication handler that GameKit invokes.
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                // If the view controller is non-nil, present it to the player so they can
                // perform some necessary action to complete authentication.
                self.rootViewController?.present(viewController, animated: true) { }
                return
            }
            if let error {
                // If you can’t authenticate the player, disable Game Center features in your game.
                print("Error: \(error.localizedDescription).")
                return
            }
            
            // A value of nil for viewController indicates successful authentication, and you can access
            // local player properties.
            
            // Load the local player's avatar.
            GKLocalPlayer.local.loadPhoto(for: GKPlayer.PhotoSize.small) { image, error in
                if let image {
                    self.playerProfileImages.append(Image(uiImage: image))
                }
                if let error {
                    // Handle an error if it occurs.
                    print("Error: \(error.localizedDescription).")
                }
            }
            
            // Register for turn-based invitations and other events.
            GKLocalPlayer.local.register(self)
        }
    }
    
    func startMatchmaking(_ playersToInvite: [GKPlayer]? = nil) {
        // Create a match request.
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        if playersToInvite != nil {
            request.recipients = playersToInvite
        }

        // Present the interface where the player selects opponents and starts the game.
        let viewController = GKMatchmakerViewController(matchRequest: request)
        viewController?.matchmakerDelegate = self
        rootViewController?.present(viewController!, animated: true) { }
    }
    
    /// Helper to load avatar and store it at the correct index
    private func loadAvatar(for player: GKPlayer, at index: Int) {
        player.loadPhoto(for: .small) { (image, error) in
            DispatchQueue.main.async {
                if let image = image {
                    // Ensure index is still valid
                    if index < self.playerProfileImages.count,
                       self.players[index].gamePlayerID == player.gamePlayerID {
                        self.playerProfileImages[index] = Image(uiImage: image)
                    }
                }
                if let error = error {
                    print("Error loading avatar: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func playersExcluding(players: [GKPlayer], excludedPlayer: GKPlayer) -> [GKPlayer] {
        return players.filter { $0.gamePlayerID != excludedPlayer.gamePlayerID }
    }
    
    func setupGame(newMatch: GKMatch, host: GKPlayer) {
        resetGame()
        
        inGame = true
        match = newMatch
        
        match!.delegate = self
        
        let allPlayers = [GKLocalPlayer.local] + match!.players
        let allExceptHost = playersExcluding(players: allPlayers, excludedPlayer: host).sorted { $0.gamePlayerID < $1.gamePlayerID }
        
        var counter = 1
        players.append(host)
        playerProfileImages = Array(repeating: Image(systemName: "person.crop.circle.fill"), count: allPlayers.count)
        loadAvatar(for: host, at: 0)
        playerHands.append([])
        playerIsEliminated.append(false)
        
        for player in allExceptHost {
            if player == localPlayer {
                localPlayerIndex = counter
            }
            
            players.append(player)
            loadAvatar(for: player, at: counter)
            playerHands.append([])
            playerIsEliminated.append(false)
            counter += 1
        }
        
        if localPlayer != host {
            // Tell host player is ready
            do {
                let data = encode(message: "ready")
                try match?.send(data!, to: [host], dataMode: GKMatch.SendDataMode.reliable)
            } catch {
                print("Error: \(error.localizedDescription).")
            }
        }
    }
    
    func startGame() {
        createDeck()
        
        for i in 0..<players.count {
            dealCards(to: i, numOfCards: 4)
        }
        
        dealCards(to: whoseTurn, numOfCards: 1)
    }
    
    func playCard(playedCard: Card, indexInHand: Int, targetPlayerIndex: Int? = nil, isMyCard: Bool = true) {
        // Prevent double inputs
        if isMyCard {
            if hasPlayed {
                return
            } else {
                hasPlayed = true
            }
        }
        
        switch playedCard.cardType {
        case .number:
            switch playedCard.value {
            case .king:
                tally = 100
            default:
                tally += Int(playedCard.value.rawValue) ?? 0
            }
            
        case .action:
            return
        }
        
        // If local player is playing the card
        if isMyCard {
            playerHands[localPlayerIndex].remove(at: indexInHand)
            
            do {
                let data = encode(playedCard: playedCard, indexInHand: indexInHand)
                try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
            } catch {
                print("Error: \(error.localizedDescription).")
            }
            
            finishTurn()
        } else {
            whoseTurn = (whoseTurn + 1) % players.count
            hasPlayed = false
        }

        discardPile.append(playedCard)
    }
    
    func dealCards(to: Int, numOfCards: Int) {
        for _ in 0..<numOfCards {
            let card = deck.removeFirst()
            playerHands[to].append(card)
        }
        
        // Do the same action on all clients
        do {
            let data = encode(targetPlayerIndex: to, numOfCards: numOfCards)
            try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
    
    func finishTurn() {
        isPlayerBusted()
        
        if discardPile.count >= reshuffleCount * 2 {
            var cardsToReshuffle = Array(discardPile.prefix(reshuffleCount))
            discardPile.removeFirst(reshuffleCount)
            cardsToReshuffle.shuffle()
            
            // Send reshuffled deck
            do {
                let data = encode(message: "reshuffle", listOfCards: cardsToReshuffle)
                try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
            } catch {
                print("Error: \(error.localizedDescription).")
            }
            
            deck.append(contentsOf: cardsToReshuffle)
        }
        
        if playerIsEliminated[whoseTurn], localPlayerIndex == whoseTurn {
            do {
                let data = encode(message: "eliminate")
                try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
            } catch {
                print("Error: \(error.localizedDescription).")
            }
            
            return
        }
        
        whoseTurn = (whoseTurn + 1) % players.count
        dealCards(to: whoseTurn, numOfCards: 1)
    }
    
    func isPlayerBusted() {
        if tally > 100 {
            playerIsEliminated[whoseTurn] = true
            tally = 100
        }
    }
    
    func eliminatePlayer(playerIndex: Int) {
        players.remove(at: playerIndex)
        playerHands.remove(at: playerIndex)
        playerProfileImages.remove(at: playerIndex)
        playerIsEliminated.remove(at: playerIndex)
        
        if playerIndex < localPlayerIndex {
            localPlayerIndex -= 1
        }
        
        if whoseTurn > players.count {
            whoseTurn -= 1
        }
        
        if players.count == 1, players[0] == localPlayer {
            localPlayerWon = true
        }
    }
    
    func checkForWinner() {
        
    }
}
