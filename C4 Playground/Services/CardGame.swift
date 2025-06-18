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
    private let maxTally = 21
    
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
    var playersReady = 0
    @Published var playersReceivedDeck = 1
    @Published var playersReceivedReshuffleCMD = 1
    
//  GK Variables
    var match: GKMatch?
    var host = GKPlayer()
    var localPlayer = GKLocalPlayer.local
    var localPlayerIndex: Int = 0
    
    //  Host will always call this function. This creates a deck, and sends it to all other players. Again, the match will not start properly until all players have received the deck. Check the receiveData's "receivedDeck" case for details.
    //  TODO: Check CardGame+GKMatchDelegate's "receivedDeck" case
    func createDeck() {
        //  TODO: Change balance of addition and subtraction.
        deck = []
        let subtractCards: [Card] = CardValue.allCases
            .filter { $0.rawValue.starts(with: "-") }
            .flatMap { value in
                Array(repeating: Card(cardType: .number, value: value), count: 6)
            }
        deck.append(contentsOf: subtractCards)
        
        let addCards: [Card] = CardValue.allCases
            .filter { !$0.rawValue.starts(with: "-") }
            .flatMap { value in
                Array(repeating: Card(cardType: .number, value: value), count: 10)
            }
        deck.append(contentsOf: addCards)
        
//        for suit in CardSuit.allCases {
//            for value in CardValue.allCases {
//                deck.append(Card(cardType: .number, value: value, suit: suit))
//            }
//        }
        deck.shuffle()
        print("there are \(deck.count) cards in the deck.")
        
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
        playersReady = 0
        playersReceivedDeck = 1
        playersReceivedReshuffleCMD = 1
        
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
    
    //  When starting matchmaking, you create a MatchRequest, and set the viewController to the GKMatchMaker view controller. This brings up the different matchmaking options (invite, automatch, etc). Logic ends here until you find a valid match.
    //  TODO: Open up Services/CardGame+GKMatchmakerViewControllerDelegate and look at the function with didFind match
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
    
    
    //  Sets up base variables for the game. resetGame is called here to reset variables before another game begins (garbage collection). Then, load data for each player. The game does not start until all players have completed this process. When done, they will send a data packet to the host to indicate that their game room is setup.
    //  TODO: Go to CardGame+GKMatchDelegate and look at the receiveData function.
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
    
    //  Host deals 4 cards to each player, and then deals 1 to itself to start the game.
    //  TODO: Double click the dealCards function and jump to definition.
    func startGame() {
        for i in 0..<players.count {
            dealCards(to: i, numOfCards: 4)
        }
        
        dealCards(to: whoseTurn, numOfCards: 1)
    }
    
    //  When the local player selects a card, it will play it (do some calculations) on the local device first, and then tell everyone to to the same.
    //  After playing, check if the deck is empty (all cards have been played). If true, then take all but one card from the discard pile, shuffle, then put it in the deck variable. Send it to all other players with the same "waiting" logic as before, to make sure everyone has received the newly shuffled deck before proceeding. This is linked to the second onChangeOf event in GameView.
    //  This same function (well actually its the finishTurn function) then increments the turn to the next player's index. When other players receive the ping, the listener tells them to run this function (so as to not repeat the logic), but skip some logic and just increment the turn to the next player's.
    //  TODO: Go to finishTurn and reshuffleDeck functions.
    func playCard(playedCard: Card, indexInHand: Int, targetPlayerIndex: Int? = nil, isMyCard: Bool = true) {
        // Prevent double inputs
        if isMyCard {
            if hasPlayed {
                return
            } else {
                hasPlayed = true
            }
        }
        
        // TODO: Implement action card logic (might involve adding some more environment variables and maybe a new separate controller / delegate just for actions.
        switch playedCard.cardType {
        case .number:
            switch playedCard.value {
            default:
                tally += Int(playedCard.value.rawValue) ?? 0
            }
            
        case .action:
            return
        }
        
        discardPile.append(playedCard)
        
        // If local player is playing the card
        if isMyCard {
            playerHands[localPlayerIndex].remove(at: indexInHand)
            
            do {
                let data = encode(playedCard: playedCard, indexInHand: indexInHand)
                try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
            } catch {
                print("Error: \(error.localizedDescription).")
            }
            
            if deck.count == 0 {
                reshuffleCards()
            } else {
                finishTurn()
            }
        } else {
            whoseTurn = (whoseTurn + 1) % players.count
            hasPlayed = false
        }
    }
   
    //  All gameplay logic functions roughly goes like this. Do the action on the local player's view, and then ping (send a data packet) indicating what action to perform to all other players. Set up the listener to do the same logic (in some cases call the same function with exceptions). In this instance, we deal the cards and then tell everyone else to do the same.
    //  When this process is complete, the host (index 0) will see their cards (start their turn). When they play a card, it will trigger the playCard function.
    //  TODO: Find the playCard function in this file
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
    
    func reshuffleCards() {
        let reshuffleCount = discardPile.count - 1
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
    
    //  Every time a player finishes playing a card, game checks if tally has gone over the limit. If true, send the death flag to all other players. If not, then pass the turn to the next player.
    func finishTurn() {
        if tally > maxTally {
            playerIsEliminated[whoseTurn] = true
        }
        
        // If busted, tell everyone
        if playerIsEliminated[whoseTurn], localPlayerIndex == whoseTurn {
            whoseTurn = (whoseTurn + 1) % players.count
            dealCards(to: whoseTurn, numOfCards: 1)
            
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
    
    // TODO: Seems to be slightly bugged, does not immediately show the you win! alert when localPlayerWon is set to true. or maybe it isn't being set, idk
    func eliminatePlayer(playerIndex: Int) {
        // If last person standing, end game
        if players.count == 2, playerIndex != localPlayerIndex {
            localPlayerWon = true
            return
        }
        
        tally = maxTally
        players.remove(at: playerIndex)
        playerHands.remove(at: playerIndex)
        playerProfileImages.remove(at: playerIndex)
        playerIsEliminated.remove(at: playerIndex)
        
        if playerIndex < localPlayerIndex {
            localPlayerIndex -= 1
        }
        
        if whoseTurn >= players.count-1 {
            whoseTurn -= 1
        }
    }
    
    func checkForWinner() {
        
    }
}
