//
//  C4_PlaygroundApp.swift
//  C4 Playground
//
//  Created by Savio Enoson on 09/06/25.
//

import SwiftUI
import SwiftData

@main
struct C4_PlaygroundApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    var mockCardGame = MockCardGame()

    var body: some Scene {
        WindowGroup {
            GameView(game: mockCardGame)
                .task {
                    mockCardGame.setupMockGame()
                    for index in 0..<Int(mockCardGame.players.count) {
                        mockCardGame.mockPreviewDealCards(to: index, numOfCards: 4)
                    }
                    // Local player is always 2 for some reason
                    mockCardGame.mockPreviewDealCards(to: 0, numOfCards: 1)
                }
//            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
 
