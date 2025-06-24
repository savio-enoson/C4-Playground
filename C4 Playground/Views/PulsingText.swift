//
//  PulsingText.swift
//  C4 Playground
//
//  Created by Savio Enoson on 24/06/25.
//

import SwiftUI


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
