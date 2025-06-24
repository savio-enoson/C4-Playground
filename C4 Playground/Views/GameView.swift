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
                        PlayersContainer(players: game.players, playerProfileImages: game.playerProfileImages, playerHands: game.playerHands, myIndex: game.localPlayerIndex)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        GameTally(game: game)
                            .position(x: dropAreaTopBound.x, y: dropAreaTopBound.y - 120)
                    }
                    .zIndex(.infinity)
                    
                    VStack {
                        Spacer()
                        
                        DiscardPileView(game: game)
                            .padding(.top, isiPad ? 200 : 100)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: geo.frame(in: .global), initial: true) { _, newFrame in
                                            dropAreaTopBound = CGPoint(x: newFrame.midX, y: newFrame.midY)
                                            positionLogged = true
                                        }
                                }
                            )
                        
                        Spacer()
                        
                        if game.whoseTurn == game.localPlayerIndex {
                            PlayerHandView(game: game)
                                .padding(.bottom)
                        }
                    }
                    
                    HStack {
                        CardDeckView(game: game)
                            .position(x: isiPad ? 150 : 75, y: UIScreen.main.bounds.midY + 100)
                        Spacer()
                    }
                }
                //  When all players have received the deck, the game can start. This time we use the game.players variable because it is faster than checking the match variable again. However, this means we need to start from 1 because game.players includes the local player.
                //  TODO: Double click the startGame function and jump to definition.
                .onChange(of: game.playersReceivedDeck, {
                    if game.playersReceivedDeck == game.players.count {
                        game.startGame()
                    }
                })
                .onChange(of: game.playersReceivedReshuffleCMD, {
                    if game.playersReceivedReshuffleCMD == game.players.count {
                        game.finishTurn()
                        game.playersReceivedReshuffleCMD = 1
                    }
                })
                .alert("You Busted! 😜", isPresented: $game.playerIsEliminated[game.localPlayerIndex]) {
                    Button("I Concede 😔") {
                        game.inGame = false
                    }
                } message: {
                    Text("Uh, oh, the tally has gone over \(game.maxTally)!")
                }
                .alert("You Won!", isPresented: $game.localPlayerWon) {
                    Button("Hurray 🎉! ") {
                        game.inGame = false
                    }
                } message: {
                    Text("You are the last player standing, way to go!")
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGame = MockCardGame()
        mockGame.setupMockGame()
        
        return GameView(game: mockGame).task {
            for index in 0..<Int(mockGame.players.count) {
                mockGame.mockPreviewDealCards(to: index, numOfCards: 4)
            }
            // Local player is always 2 for some reason
            mockGame.mockPreviewDealCards(to: 0, numOfCards: 1)
        }
    }
}

class MockCardGame: CardGame {
    func setupMockGame() {
        // Setup mock game state
        inGame = true
        deck = []

        let subtractCards: [Card] = CardValue.allCases
            .filter { $0.rawValue.starts(with: "-") }
            .flatMap { value in
                (0..<6).map { _ in Card(cardType: .number, value: value) } // New card each time
            }
        
        let addCards: [Card] = CardValue.allCases
            .filter { !$0.rawValue.starts(with: "-") }
            .flatMap { value in
                (0..<10).map { _ in Card(cardType: .number, value: value) } // New card each time
            }
        
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
        let emptyArr: [Card] = []
        playerHands = Array(repeating: emptyArr, count: players.count)
        
        // Mock profile images
        playerProfileImages = Array(repeating: Image(systemName: "person.circle"), count: players.count)
        
        playerIsEliminated = Array(repeating: false, count: players.count)
        localPlayerIndex = 0
        whoseTurn = localPlayerIndex
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
