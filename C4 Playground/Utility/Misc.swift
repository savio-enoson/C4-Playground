//
//  Misc.swift
//  C4 Playground
//
//  Created by Savio Enoson on 12/06/25.
//

import Foundation
import SwiftUI

extension View {
    func getGlobalYPosition(completion: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: GlobalPositionKey.self,
                        value: geometry.frame(in: .global).origin.y
                    )
                    .onAppear {
                        completion(geometry.frame(in: .global).origin.y)
                    }
            }
        )
    }
    
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

struct GlobalPositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct GameEndAlertContainer<Content: View>: View {
    let content: Content
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Darkened overlay
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            // Alert content
            VStack {
                Spacer()
                
                content
                    .padding(.bottom, 100)
                
                Spacer()
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .transition(.opacity)
        .zIndex(100) // Ensure it appears above everything
    }
}

/// Returns an emoji string corresponding to a given status effect type.
func emoji(for effectType: CardValue) -> String {
    switch effectType {
    case .jinx_banana:
        return "🍌"
    case .jinx_confusion:
        return "❓"
    case .jinx_hallucination:
        return "🌀"
    case .jinx_blackout:
        return "🕶️"
    case .jinx_dementia:
        return "🧠"
    default:
        return "" // Return an empty string for any other unhandled cases
    }
}
