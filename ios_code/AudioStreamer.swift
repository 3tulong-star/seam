import AVFoundation

final class AudioStreamer: NSObject {
    private let audioEngine = AVAudioEngine()
    private var converter: AVAudioConverter?

    var onAudioBuffer: ((String) -> Void)?

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setPreferredSampleRate(16000)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        print("AudioStreamer input format:", inputFormat.sampleRate, inputFormat.channelCount)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "AudioStreamer", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create target format"])
        }

        converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        let bufferSize: AVAudioFrameCount = 1024

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            guard let self, let converter = self.converter else { return }
            if buffer.frameLength == 0 { return }

            let ratio = inputFormat.sampleRate / targetFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) / ratio) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

            var error: NSError?
            let status = converter.convert(to: converted, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            if status == .error || error != nil { return }
            if converted.frameLength == 0 { return }
            guard let ch = converted.int16ChannelData else { return }

            let len = Int(converted.frameLength) * MemoryLayout<Int16>.size
            let data = Data(bytes: ch[0], count: len)
            self.onAudioBuffer?(data.base64EncodedString())
        }

        try audioEngine.start()
        print("AudioStreamer started")
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        // 不在这里 setActive(false)，避免打断系统其他音频（TTS）
    }
}
