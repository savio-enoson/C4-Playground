//
//  MainMenuView.swift
//  C4 Playground
//
//  Created by Savio Enoson on 18/06/25.
//

import SwiftUI

struct MainMenuView: View {
    let isiPad: Bool = (UIDevice.current.userInterfaceIdiom == .pad);

    @State var positionLogged = false
    @State var titlePosition: CGPoint = CGPoint(x: 0, y: 0)
    
    @ObservedObject var game: CardGame
    var cardCarouselDeck: [Card] = [
        Card(cardType: .number, value: .add_1),
        Card(cardType: .number, value: .subtract_5),
        Card(cardType: .number, value: .subtract_2),
        Card(cardType: .number, value: .add_4),
        Card(cardType: .number, value: .add_2),
        Card(cardType: .number, value: .subtract_4),
        Card(cardType: .number, value: .add_3),
        Card(cardType: .number, value: .subtract_3),
        Card(cardType: .number, value: .add_5),
        Card(cardType: .number, value: .subtract_1),
    ]
    
    var body: some View {
        ZStack {
            Color("backgroundColor")
            
            VStack {
                Spacer()
                
                Image("game_title")
                    .resizable()
                    .scaledToFit()
                    .frame(minHeight: 80, maxHeight: isiPad ? 160 : 100)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global), initial: true) { _, newFrame in
                                    titlePosition = CGPoint(x: newFrame.maxX, y: newFrame.maxY)
                                    positionLogged = true
                                }
                        }
                    )
                
                Spacer()
                
                CardCarousel(cards: cardCarouselDeck)
                                .padding()
                
                Spacer()
             
                VStack(spacing: 20)  {
                    Button {
                        game.startMatchmaking()
                    } label: {
                        ZStack {
                            Image("pxlButtonBackground")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                            
                            Text("Start")
                                .font(.cLargeTitle)
                                .foregroundColor(.black)
                        }
                    }
                    
                    Button {
                        print("Pressed How to Play")
                        game.playCardSound()
                        game.playCardHaptic()
                    } label: {
                        ZStack {
                            Image("pxlButtonBackground")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                            
                            Text("How to Play")
                                .font(.cLargeTitle)
                                .foregroundColor(.black)
                        }
                    }
                }
                
                Spacer()
            }
            
            if positionLogged {
                PulsingText(text: "Bust together with friends!!")
                    .position(x: titlePosition.x - 40, y: titlePosition.y + 40)
                    .rotationEffect(Angle(degrees: -10.0))
            }
        }
        .ignoresSafeArea(.all)
//        .task {
//            print(cardCarouselDeck[0].imageName)
//        }
    }
}

struct CardCarousel: View {
    let cards: [Card]
    let cardWidth: CGFloat = min(200, UIScreen.main.bounds.width * 0.34)
    let spacing: CGFloat = 60
    let scrollSpeed: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 90 : 60 // pixels per second
    
    private var totalWidth: CGFloat {
        CGFloat(cards.count) * (cardWidth + spacing)
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let progress = elapsed * Double(scrollSpeed)
            let offset = CGFloat(progress).truncatingRemainder(dividingBy: totalWidth)
            
            GeometryReader { geometry in
                let visibleWidth = geometry.size.width
                let neededDuplicates = Int(ceil(visibleWidth / (cardWidth + spacing))) + 1
                
                HStack(spacing: spacing) {
                    // Original cards + duplicates
                    ForEach(0..<(cards.count + neededDuplicates), id: \.self) { index in
                        let card = cards[index % cards.count]
                        CardView(card: card, isFaceUp: true)
                            .frame(width: cardWidth)
                    }
                }
                .offset(x: -offset)
            }
            .frame(height: cardWidth * (3.5/2.5))
        }
    }
}

struct PulsingText: View {
    let isiPad: Bool = (UIDevice.current.userInterfaceIdiom == .pad);

    let text: String
    let baseColor: Color = Color(.orange)
    let pulseScale: CGFloat = 1.34
    let pulseDuration: Double = 1.5
    
    @State private var isPulsing = false
    
    var body: some View {
        Text(text)
            .font(isiPad ? .cTitle : .cSubheadline)
            .foregroundColor(baseColor)
            .scaleEffect(isPulsing ? pulseScale : 1.0)
            .animation(
                .easeInOut(duration: pulseDuration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

#Preview {
    MainMenuView(game: CardGame())
}
