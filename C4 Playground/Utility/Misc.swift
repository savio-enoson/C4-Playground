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
