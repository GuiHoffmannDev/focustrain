import Foundation
import AVFoundation

/// Plays the optional printer loop during the boarding-pass print animation.
/// Gracefully no-ops if the audio asset isn't bundled, so the feature
/// works without `Resources/Sounds/printer.caf` present.
final class PrinterSoundPlayer {
    private var player: AVAudioPlayer?

    init() {
        let candidates: [(String, String)] = [
            ("printer", "caf"),
            ("printer", "wav"),
            ("printer", "m4a")
        ]
        for (name, ext) in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                player = try? AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.volume = 0.6
                player?.prepareToPlay()
                return
            }
        }
    }

    func start() { player?.play() }

    func stop() {
        guard let player else { return }
        player.stop()
        player.currentTime = 0
    }
}
