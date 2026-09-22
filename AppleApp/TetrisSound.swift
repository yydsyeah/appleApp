//
//  TetrisSound.swift
//  AppleApp
//
//  音效与背景音乐播放器：使用 AVAudioPlayer 播放打包在 Sounds/ 中的 WAV。
//

import AVFoundation

/// 播放器：音效按事件映射到独立 WAV，BGM 循环播放。
final class TetrisSoundPlayer: ObservableObject {

    @Published var enabled = true

    private var effects: [String: AVAudioPlayer] = [:]
    private var music: AVAudioPlayer?

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // MARK: 音效

    func play(_ event: TetrisEvent) {
        guard enabled else { return }
        let name: String
        switch event {
        case .move: name = "move"
        case .rotate: name = "rotate"
        case .softDrop: name = "softdrop"
        case .hardDrop: name = "harddrop"
        case .hold: name = "hold"
        case .lock: name = "lock"
        case .clear(let count): name = count >= 4 ? "tetris" : "clear"
        case .levelUp: name = "levelup"
        case .gameOver: name = "gameover"
        }
        guard let player = effect(named: name) else { return }
        player.currentTime = 0
        player.play()
    }

    // MARK: 背景音乐

    func startMusic() {
        guard enabled else { return }
        if music == nil {
            guard let player = load(named: "bgm") else { return }
            player.numberOfLoops = -1
            player.volume = 1.0
            music = player
        }
        music?.currentTime = 0
        music?.play()
    }

    func pauseMusic() {
        music?.pause()
    }

    func resumeMusic() {
        guard enabled else { return }
        music?.play()
    }

    func stopMusic() {
        music?.stop()
        music?.currentTime = 0
    }

    // MARK: 内部

    private func effect(named name: String) -> AVAudioPlayer? {
        if let existing = effects[name] {
            return existing
        }
        guard let player = load(named: name) else { return nil }
        player.volume = 0.75
        effects[name] = player
        return player
    }

    private func load(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            return nil
        }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }
}
