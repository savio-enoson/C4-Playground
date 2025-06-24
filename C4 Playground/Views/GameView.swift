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
    @State private var showBustedAlert = false
    @State private var showWinnerAlert = false
    
    @State private var showDropArea = false
    @State private var dropAreaSize: CGSize = .init(width: isiPad ? 400.0 : 300.0, height: isiPad ? 300.0 : 200.0)

    @State var dropAreaTopBound = CGPoint(x: 0, y: 0)
    @State var positionLogged = false
    
    @ObservedObject var game: CardGame
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
            
            if game.inGame {
                ZStack {
                    ZStack {
                        PlayersContainer(game: game)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        GameTally(game: game)
                            .position(x: dropAreaTopBound.x, y: dropAreaTopBound.y - (isiPad ? 240 : 200))
                    }
                    .zIndex(.infinity)
                    
                    DiscardPileView(game: game)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .global), initial: true) { _, newFrame in
                                        dropAreaTopBound = CGPoint(x: newFrame.midX, y: newFrame.midY)
                                        positionLogged = true
                                    }
                            }
                        )
                        .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
                    
                    HStack {
                        CardDeckView(game: game)
                            .position(x: isiPad ? 120 : 60, y: UIScreen.main.bounds.midY + 100)
                        Spacer()
                    }
                    
                    PlayerHandView(game: game)
                        .frame(maxWidth: .infinity)
                        .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY - 75)
                        .offset(x: 0, y: (game.whoseTurn == game.localPlayerIndex) ? -100 : 0)
                        .animation(.easeInOut, value: game.whoseTurn)
                }
                //  When all players have received the deck, the game can start. This time we use the game.players variable because it is faster than checking the match variable again. However, this means we need to start from 1 because game.players includes the local player.
                //  TODO: Double click the startGame function and jump to definition.
                .onChange(of: game.playersReceivedDeck, {
                    if game.playersReceivedDeck == game.players.count, game.host == GKLocalPlayer.local {
                        game.startGame()
                    }
                })
                .onChange(of: game.playersReceivedReshuffleCMD, {
                    if game.playersReceivedReshuffleCMD == game.players.count, game.host == GKLocalPlayer.local {
                        game.finishTurn()
                        game.playersReceivedReshuffleCMD = 1
                    }
                })
            }
        }
        .edgesIgnoringSafeArea(.all)
        
        if game.inGame {
            // Alert overlays
            if game.playerIsEliminated[game.localPlayerIndex] {
                GameEndAlertContainer(
                    content: BustedAlertView(playerName: game.localPlayer.displayName) {
                        game.inGame = false
                    },
                    onDismiss: {
                        game.inGame = false
                    }
                )
            }
            
            if game.localPlayerWon {
                GameEndAlertContainer(
                    content: WinnerAlertView(playerName: game.localPlayer.displayName) {
                        game.inGame = false
                    },
                    onDismiss: {
                        game.inGame = false
                    }
                )
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGame = MockCardGame()
        mockGame.setupMockGame()
        mockGame.setupAudio()
        mockGame.setupHaptics()
        
        return GameView(game: mockGame)
            .onAppear {
                for index in 0..<mockGame.players.count {
                    mockGame.mockPreviewDealCards(to: index, numOfCards: 4)
                }
                mockGame.mockPreviewDealCards(to: 0, numOfCards: 1)
            }
    }
}


class MockCardGame: CardGame {
    func setupMockGame() {
        // Setup mock game state
        inGame = true
        deck = []
        
        localPlayerIndex = 0
        whoseTurn = localPlayerIndex

        let subtractCards: [Card] = CardValue.allCases
            .filter {
                $0.rawValue.starts(with: "-") &&
                !$0.rawValue.starts(with: "jinx") &&
                !$0.rawValue.starts(with: "trump")
            }
            .flatMap { value in
                (0..<6).map { _ in Card(cardType: .number, value: value) } // New card each time
            }
        
        let addCards: [Card] = CardValue.allCases
            .filter {
                !$0.rawValue.starts(with: "-") &&
                !$0.rawValue.starts(with: "jinx") &&
                !$0.rawValue.starts(with: "trump")
            }
            .flatMap { value in
                (0..<10).map { _ in Card(cardType: .number, value: value) } // New card each time
            }
        
        // Total 3
        let jinxCards: [Card] = CardValue.allCases
            .filter {
                $0.rawValue.starts(with: "jinx")
            }
            .flatMap { value in
                (0..<1).map { _ in Card(cardType: .action, value: value) }
            }
        
        // 2 of each
        let trumpCards: [Card] = CardValue.allCases
            .filter { $0.rawValue.starts(with: "trump") }
            .flatMap { value in
                (0..<2).map { _ in Card(cardType: .action, value: value) }
            }
        
        deck.append(contentsOf: jinxCards)
        deck.append(contentsOf: trumpCards)
        deck.append(contentsOf: subtractCards)
        deck.append(contentsOf: addCards)
        deck.shuffle()
        
        tally = 0
        
        discardPile = []
        
        // Mock players
        players = [
            MockPlayer(displayName: "You"),
            MockPlayer(displayName: "Player 1"),
            MockPlayer(displayName: "Player 2"),
            MockPlayer(displayName: "Player 3"),
        ]
        
        // Mock player hands
        let emptyHands: [Card] = []
        playerHands = Array(repeating: emptyHands, count: players.count)
        
        let emptyStatus: [StatusEffect] = []
        activeJinxEffects = Array(repeating: emptyStatus, count: players.count)
        activeJinxEffects[0] = [
            StatusEffect(type: .jinx_banana, duration: 1),
            StatusEffect(type: .jinx_confusion, duration: 1)
        ]
        
        // Mock profile images
        playerProfileImages = Array(repeating: Image(systemName: "person.circle"), count: players.count)
        
        playerIsEliminated = Array(repeating: false, count: players.count)
    }
    
    func mockPreviewDealCards(to: Int, numOfCards: Int) {
        for _ in 0..<numOfCards {
            let card = deck.removeFirst()
            playerHands[to].append(card)
        }
    }
}

// Mock GKPlayer for preview purposes
class MockPlayer: GKPlayer {
    private let _displayName: String
    
    init(displayName: String) {
        self._displayName = displayName
        super.init()
    }
    
    override var displayName: String {
        return _displayName
    }
}
