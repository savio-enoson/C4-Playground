//
//  PixelatedSquircleButton.swift
//  C4 Playground
//
//  Created by Savio Enoson on 18/06/25.
//


import SwiftUI

struct PixelatedSquircleButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding()
                .frame(minWidth: 100)
                .background(
                    // Pixelated squircle effect
                    ZStack {
                        // Base squircle shape
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.blue)
                        
                        // Pixel pattern overlay
                        Image(systemName: "square.grid.3x3")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            )
                            .font(.system(size: 8))
                            .scaleEffect(4)
                            .rotationEffect(.degrees(45))
                            .opacity(0.7)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.blue.opacity(0.5), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct PixelatedSquircleButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            PixelatedSquircleButton(title: "START GAME") {
                print("Button tapped!")
            }
            .padding()
        }
    }
}