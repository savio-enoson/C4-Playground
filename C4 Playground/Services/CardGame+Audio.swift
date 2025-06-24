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
        guard let soundURL = Bundle.main.url(forResource: "play_card", withExtension: "wav") else {
            print("Error: Couldn't find play_card.wav")
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

// Background Music

extension CardGame {    
    func playBackgroundMusic(named name: String, fadeDuration: TimeInterval = 1.5) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else {
            print("Music file \(name) not found.")
            return
        }

        fadeOutCurrentMusic(duration: fadeDuration) {
            do {
                self.musicPlayer = try AVAudioPlayer(contentsOf: url)
                self.musicPlayer?.volume = 0
                self.musicPlayer?.numberOfLoops = -1
                self.musicPlayer?.prepareToPlay()
                self.musicPlayer?.play()
                self.fadeInMusic(duration: fadeDuration)
            } catch {
                print("Error loading \(name): \(error.localizedDescription)")
            }
        }
    }

    private func fadeInMusic(duration: TimeInterval) {
        fadeTimer?.invalidate()
        guard let player = musicPlayer else { return }
        let step: Float = 0.05
        fadeTimer = Timer.scheduledTimer(withTimeInterval: duration * Double(step), repeats: true) { timer in
            player.volume += step
            if player.volume >= self.bgmVolume {
                player.volume = self.bgmVolume
                timer.invalidate()
            }
        }
    }

    private func fadeOutCurrentMusic(duration: TimeInterval, completion: @escaping () -> Void) {
        fadeTimer?.invalidate()
        guard let player = musicPlayer else {
            completion()
            return
        }

        let step: Float = 0.05
        fadeTimer = Timer.scheduledTimer(withTimeInterval: duration * Double(step), repeats: true) { timer in
            player.volume -= step
            if player.volume <= 0 {
                player.stop()
                player.volume = self.bgmVolume
                timer.invalidate()
                completion()
            }
        }
    }
}
