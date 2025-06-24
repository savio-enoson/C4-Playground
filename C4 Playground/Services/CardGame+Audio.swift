//
//  CardGame+Audio.swift
//  C4 Playground
//
//  Created by Savio Enoson on 23/06/25.
//

import Foundation
import AVFoundation
import CoreHaptics


extension CardGame {
    func setupAudio() {
        guard let soundURL = Bundle.main.url(forResource: "play_card", withExtension: "mp3") else {
            print("Error: Couldn't find play_card.caf")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }
    
    func playCardSound() {
        audioPlayer?.play()
    }
}

extension CardGame {
    func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported on this device")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Error starting haptic engine: \(error.localizedDescription)")
        }
    }
    
    func playCardHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [sharpness, intensity],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            hapticPlayer = try hapticEngine?.makePlayer(with: pattern)
            try hapticPlayer?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}
