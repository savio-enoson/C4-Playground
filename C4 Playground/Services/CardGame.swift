//
//  CardGame.swift
//  C4 Playground
//
//  Created by Savio Enoson on 09/06/25.
//
import Foundation
import SwiftUI
import GameKit
import AVFoundation
import CoreHaptics


class CardGame: NSObject, ObservableObject {
//  Gameplay Variables
    @Published var inGame: Bool = false
    @Published var deck: [Card] = []
    @Published var tally: Int = 0
    @Published var discardPile: [Card] = []
    @Published var maxTally = 21
    
//  Player-Related Gameplay Variables
    var players: [GKPlayer] = []
    @Published var whoseTurn: Int = 0
    @Published var playerHands: [[Card]] = []
    var playerProfileImages: [Image] = []
    @Published var playerIsEliminated: [Bool] = []
    var hasPlayed = false
    @Published var localPlayerWon = false
    var playersReady = 0
    
    @Published var playersReceivedDeck = 1
    @Published var playersReceivedReshuffleCMD = 1
    
    //    Main Menu Variables
    var mainMenuScene: MainMenuScene?

    var playedCardMainMenu: CardNode?
    var playedCardOriginalPositionMainMenu: CGPoint?
    
//  Action Cards Variables
    @Published var activeJinxEffects: [[StatusEffect]] = []
    
//  GK Variables
    var match: GKMatch?
    var host = GKPlayer()
    var localPlayer = GKLocalPlayer.local
    var localPlayerIndex: Int = 0
    
    // Audio
    var audioPlayer: AVAudioPlayer?
    var musicPlayer: AVAudioPlayer?
    var fadeTimer: Timer?
    var bgmVolume: Float = 0.35
    
    // Haptics
    var hapticEngine: CHHapticEngine?
    var hapticPlayer: CHHapticPatternPlayer?
    
    //  Host will always call this function. This creates a deck, and sends it to all other players. Again, the match will not start properly until all players have received the deck. Check the receiveData's "receivedDeck" case for details.
    //  TODO: Check CardGame+GKMatchDelegate's "receivedDeck" case
    func createDeck() {
        deck = []
        
        let subtractCards: [Card] = CardValue.allCases
            .filter {
                $0.rawValue.starts(with: "-") &&
                !$0.rawValue.starts(with: "jinx") &&
                !$0.rawValue.starts(with: "trump")
            }
            .flatMap { value in
                (0..<1).map { _ in Card(cardType: .number, value: value) } // New card each time
            }
        
        //
        let addCards: [Card] = CardValue.allCases
            .filter {
                !$0.rawValue.starts(with: "-") &&
                !$0.rawValue.starts(with: "jinx") &&
                !$0.rawValue.starts(with: "trump")
            }
            .flatMap { value in
                (0..<3).map { _ in Card(cardType: .number, value: value) } // New card each time
            }
        
        // Get all available jinx card types
        let allJinxTypes = CardValue.allCases.filter {
            $0.rawValue.starts(with: "jinx")
        }

        // Select 3 random jinx cards from the available types
        let jinxCards: [Card] = Array(allJinxTypes.shuffled().prefix(3)).map { value in
            Card(cardType: .action, value: value)
        }
        
        // Create one card for each available trump card type
        let trumpCards: [Card] = CardValue.allCases
            .filter { $0.rawValue.starts(with: "trump") }
            .map { value in
                Card(cardType: .action, value: value)
            }
        
        deck.append(contentsOf: jinxCards)
        deck.append(contentsOf: trumpCards)
        deck.append(contentsOf: subtractCards)
        deck.append(contentsOf: addCards)
        deck.shuffle()
        
        // Send shuffled deck to sync between all players
        do {
            let data = encode(message: "init", listOfCards: deck)
            try match?.sendData(toAllPlayers: data!, with: .reliable)
        } catch {
            print("Error sending deck: \(error.localizedDescription)")
        }
    }
    
    func resetGame() {
        // Gameplay Variables
        deck = []
        tally = 0
        maxTally = 21
        discardPile = []
        
        // Player-Related Gameplay Variables
        whoseTurn = 0
        players.removeAll()
        playerHands.removeAll()
        playerIsEliminated.removeAll()
        playerProfileImages.removeAll()
        activeJinxEffects.removeAll()
        activeJinxEffects.removeAll()
        
        hasPlayed = false
        localPlayerWon = false
        playersReady = 0
        playersReceivedDeck = 1
        playersReceivedReshuffleCMD = 1
        
        // GK Variables
        match?.disconnect()
        match?.delegate = nil
//        GKAccessPoint.shared.isActive = true
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
    
    private func setupPlayer(player: GKPlayer, index: Int) {
        players.append(player)
        loadAvatar(for: player, at: index)
        playerHands.append([])
        playerIsEliminated.append(false)
        activeJinxEffects.append([])
    }
    
    //  Sets up base variables for the game. resetGame is called here to reset variables before another game begins (garbage collection). Then, load data for each player. The game does not start until all players have completed this process. When done, they will send a data packet to the host to indicate that their game room is setup.
    //  TODO: Go to CardGame+GKMatchDelegate and look at the receiveData function.
    func setupGame(newMatch: GKMatch, host: GKPlayer) {
        resetGame()
//        GKAccessPoint.shared.isActive = false
        
        inGame = true
        match = newMatch
        match!.delegate = self
        
        let allPlayers = [GKLocalPlayer.local] + match!.players
        let allExceptHost = playersExcluding(players: allPlayers, excludedPlayer: host).sorted { $0.gamePlayerID < $1.gamePlayerID }
        
        var counter = 1
        playerProfileImages = Array(repeating: Image(systemName: "person.crop.circle.fill"), count: allPlayers.count)
        setupPlayer(player: host, index: 0)
        
        for player in allExceptHost {
            if player == GKLocalPlayer.local {
                localPlayerIndex = counter
                print("setting my index to \(counter)")
            }
            
            setupPlayer(player: player, index: counter)
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
        } else {
            // Ensure host is at index 0
            localPlayerIndex = 0
        }
    }
    
    //  Host deals 4 cards to each player, and then deals 1 to itself to start the game.
    //  TODO: Double click the dealCards function and jump to definition.
    func startGame() {
        for i in 0..<players.count {
            dealCards(to: i, numOfCards: 4)
        }
        
        dealCards(to: whoseTurn, numOfCards: 1)
        
        print(playerHands)
        print(players.count)
        print(whoseTurn)
    }
    
    func changeLimit(amount: Int) {
        if (maxTally + amount) < tally {
            tally = maxTally + amount
        }
        maxTally += amount
    }
    
    //  When the local player selects a card, it will play it (do some calculations) on the local device first, and then tell everyone to to the same.
    //  After playing, check if the deck is empty (all cards have been played). If true, then take all but one card from the discard pile, shuffle, then put it in the deck variable. Send it to all other players with the same "waiting" logic as before, to make sure everyone has received the newly shuffled deck before proceeding. This is linked to the second onChangeOf event in GameView.
    //  This same function (well actually its the finishTurn function) then increments the turn to the next player's index. When other players receive the ping, the listener tells them to run this function (so as to not repeat the logic), but skip some logic and just increment the turn to the next player's.
    //  TODO: Go to finishTurn and reshuffleDeck functions.
    func playCard(playedCard: Card, indexInHand: Int, targetPlayerIndex: Int? = nil, isMyCard: Bool = true) {
        if isMyCard {
            // Handle dragging card into center out of turn
            if whoseTurn != localPlayerIndex {
                return
            }
            // Prevent double inputs
            if hasPlayed {
                return
            } else {
                hasPlayed = true
            }
        }
        
        // TODO: Implement action card logic (might involve adding some more environment variables and maybe a new separate controller / delegate just for actions.
        switch playedCard.cardType {
        case .number:
            print("Current Card Value: \(playedCard.value.rawValue)")
            tally += Int(playedCard.value.rawValue) ?? 0
            if tally <= -maxTally {
                tally = -maxTally
            }

        case .action:
            let targetIndex = findNextPlayer()
            switch playedCard.value {
            case .jinx_banana:
                activeJinxEffects[targetIndex].append(StatusEffect(type: .jinx_banana, duration: 2))
            case .jinx_confusion:
                activeJinxEffects[targetIndex].append(StatusEffect(type: .jinx_confusion, duration: 4))
            case .jinx_hallucination:
                activeJinxEffects[targetIndex].append(StatusEffect(type: .jinx_hallucination, duration: 3))
            case .jinx_blackout:
                activeJinxEffects[targetIndex].append(StatusEffect(type: .jinx_blackout, duration: 3))
            case .jinx_dementia:
                activeJinxEffects[targetIndex].append(StatusEffect(type: .jinx_dementia, duration: 3))
            case .trump_wipeout:
                tally = 0
            case .trump_maxout:
                if maxTally < 21 {
                    tally = maxTally
                } else {
                    tally = 21
                }
            case .trump_limitchange:
                if isMyCard {
                    let changeBy = Int.random(in: -2...2)
                    changeLimit(amount: changeBy)
                    
                    // Change limit for every player
                    do {
                        let data = encode(message: "changeLimit", adjustBy: changeBy)
                        try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
                    } catch {
                        print("Error: \(error.localizedDescription).")
                    }
                }
            default:
                print("action card logic not registered.")
            }
        }
        
        discardPile.append(playedCard)
//        playCardSound()
        
        // If local player is playing the card
        if isMyCard {
            playerHands[localPlayerIndex].remove(at: indexInHand)
            
            do {
                let data = encode(playedCard: playedCard, indexInHand: indexInHand)
                try match?.sendData(toAllPlayers: data!, with: GKMatch.SendDataMode.reliable)
            } catch {
                print("Error: \(error.localizedDescription).")
            }
            
            // Reshuffle deck when out of cards
            if deck.count == 0 {
                reshuffleCards()
            }
        }
        
        finishTurn()
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
        
        cardsToReshuffle.removeAll { card in
                card.value.rawValue.starts(with: "jinx")
            }
        let allJinxTypes = CardValue.allCases.filter {
                $0.rawValue.starts(with: "jinx")
            }
        let newJinxCards: [Card] = Array(allJinxTypes.shuffled().prefix(allJinxTypes.count)).map { value in
                Card(cardType: .action, value: value)
            }
        cardsToReshuffle.append(contentsOf: newJinxCards)
        
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
        let myTurn = whoseTurn == localPlayerIndex
        
        // Bust check :P
        if tally > maxTally {
            playerIsEliminated[whoseTurn] = true
        }
        
        let myStatusEffects = activeJinxEffects[whoseTurn]
        let hasBanana = myStatusEffects.contains { $0.type == .jinx_banana }
        
        if !hasBanana {
            // Advance to next player
            whoseTurn = findNextPlayer()
        }
        
        // Check if all players are eliminated (except possibly current player)
        checkWinCondition()
        
        if myTurn {
            dealCards(to: whoseTurn, numOfCards: 1)
            hasPlayed = false
        }
        
        // Update Status Effects
        updateStatusEffect(playerIndex: whoseTurn)
    }
    
    private func updateStatusEffect(playerIndex : Int) {
        // Update Status Effects
        var effectsToRemove = [Int]() // Track indices to remove

        // First pass: increment time and mark expired effects
        for index in activeJinxEffects[playerIndex].indices {
            activeJinxEffects[playerIndex][index].incrementTime()
            
            if activeJinxEffects[playerIndex][index].timeElapsed! >=
               activeJinxEffects[playerIndex][index].duration {
                effectsToRemove.append(index)
            }
        }

        // Second pass: remove expired effects in reverse order
        for index in effectsToRemove.sorted(by: >) {
            activeJinxEffects[playerIndex].remove(at: index)
        }
    }
    
    private func checkWinCondition() {
        // Ensure we have valid player data
        guard !playerIsEliminated.isEmpty,
              localPlayerIndex < playerIsEliminated.count else {
            return
        }
        
        // Check if all other players are eliminated
        let otherPlayersEliminated = playerIsEliminated.enumerated().allSatisfy { index, isEliminated in
            index == localPlayerIndex || isEliminated
        }
        
        if otherPlayersEliminated {
            localPlayerWon = true
        }
    }
    
    private func findNextPlayer() -> Int {
        var testIndex = whoseTurn
        // Advance to next player
        testIndex = (testIndex + 1) % players.count
        
        // Skip eliminated players
        while playerIsEliminated[testIndex] {
            testIndex = (testIndex + 1) % players.count
        }
        
        return testIndex
    }
}
