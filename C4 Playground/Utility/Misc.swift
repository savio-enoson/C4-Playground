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


func findMostFrequent(in numbers: [Int]) -> Int? {
    // Return nil if the array is empty
    guard !numbers.isEmpty else {
        return nil
    }

    // 1. Create a frequency dictionary
    // Example: [1, 2, 2, 3] -> [1: 1, 2: 2, 3: 1]
    var counts: [Int: Int] = [:]
    for number in numbers {
        counts[number, default: 0] += 1
    }

    // 2. Find the key-value pair with the highest value (count)
    // The 'max(by:)' method finds the element in a sequence that has the
    // maximum value based on the provided closure.
    if let (mostFrequentNumber, _) = counts.max(by: { $0.value < $1.value }) {
        return mostFrequentNumber
    }

    return nil // Should not happen if the array is not empty
}
