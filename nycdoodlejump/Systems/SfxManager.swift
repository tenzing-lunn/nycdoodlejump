import AVFoundation

final class SfxManager {
    static let shared = SfxManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var isReady = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        setup()
    }

    func playCoin() {
        playTone(frequency: 880, duration: 0.08, volume: 0.22)
    }

    func playLand(isSpring: Bool) {
        if isSpring {
            playTone(frequency: 520, duration: 0.08, volume: 0.2)
        } else {
            playNoise(duration: 0.06, volume: 0.16)
        }
    }

    func playDanger() {
        playToneSweep(from: 420, to: 720, duration: 0.22, volume: 0.18)
    }

    private func setup() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: [])
            try engine.start()
            player.play()
            isReady = true
        } catch {
            isReady = false
        }
    }

    private func ensureReady() {
        if isReady { return }
        setup()
    }

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        ensureReady()
        guard isReady, let buffer = makeToneBuffer(frequency: frequency, duration: duration, volume: volume) else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    private func playToneSweep(from start: Double, to end: Double, duration: Double, volume: Float) {
        ensureReady()
        guard isReady, let buffer = makeSweepBuffer(start: start, end: end, duration: duration, volume: volume) else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    private func playNoise(duration: Double, volume: Float) {
        ensureReady()
        guard isReady, let buffer = makeNoiseBuffer(duration: duration, volume: volume) else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    private func makeToneBuffer(frequency: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData?[0]
        let ramp = max(1, Int(Double(frameCount) * 0.1))
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let sample = sin(2.0 * Double.pi * frequency * t)
            let env = envelope(i: i, count: Int(frameCount), ramp: ramp)
            data?[i] = Float(sample) * volume * env
        }
        return buffer
    }

    private func makeSweepBuffer(start: Double, end: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData?[0]
        let ramp = max(1, Int(Double(frameCount) * 0.12))
        for i in 0..<Int(frameCount) {
            let t = Double(i) / format.sampleRate
            let ft = start + (end - start) * (Double(i) / Double(frameCount))
            let sample = sin(2.0 * Double.pi * ft * t)
            let env = envelope(i: i, count: Int(frameCount), ramp: ramp)
            data?[i] = Float(sample) * volume * env
        }
        return buffer
    }

    private func makeNoiseBuffer(duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData?[0]
        let ramp = max(1, Int(Double(frameCount) * 0.2))
        for i in 0..<Int(frameCount) {
            let sample = Float.random(in: -1...1)
            let env = envelope(i: i, count: Int(frameCount), ramp: ramp)
            data?[i] = sample * volume * env
        }
        return buffer
    }

    private func envelope(i: Int, count: Int, ramp: Int) -> Float {
        if i < ramp {
            return Float(i) / Float(ramp)
        }
        if i > count - ramp {
            return Float(count - i) / Float(ramp)
        }
        return 1.0
    }
}
