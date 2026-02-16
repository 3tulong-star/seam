import AVFoundation

class AudioStreamer: NSObject {
    private let audioEngine = AVAudioEngine()
    private var converter: AVAudioConverter?
    var onAudioBuffer: ((String) -> Void)?

    func start() throws {
        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.inputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)!
        converter = AVAudioConverter(from: nativeFormat, to: targetFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nativeFormat) { buffer, _ in
            self.resample(buffer: buffer, targetFormat: targetFormat)
        }
        try audioEngine.start()
    }

    private func resample(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        let ratio = buffer.format.sampleRate / targetFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) / ratio) + 1
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }
        
        var error: NSError?
        converter?.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let channelData = outputBuffer.int16ChannelData {
            let data = Data(bytes: channelData[0], count: Int(outputBuffer.frameLength) * 2)
            onAudioBuffer?(data.base64EncodedString())
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
