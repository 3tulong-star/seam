import SwiftUI

class ConversationViewModel: ObservableObject {
    @Published var partialText = ""
    @Published var messages: [String] = []
    @Published var isRecording = false
    
    private let wsClient = RealtimeWSClient()
    private let streamer = AudioStreamer()
    
    func start() {
        isRecording = true
        partialText = ""
        // TODO: 在这里填入你 Railway 部署后生成的 wss 地址
        let urlString = "wss://你的域名/api/v1/asr/realtime"
        guard let url = URL(string: urlString) else { return }
        
        wsClient.connect(url: url, lang: "zh")
        wsClient.onPartialText = { self.partialText = $0 }
        wsClient.onFinalText = { 
            self.messages.append($0)
            self.partialText = ""
        }
        streamer.onAudioBuffer = { self.wsClient.sendAudio(base64: $0) }
        try? streamer.start()
    }
    
    func stop() {
        isRecording = false
        streamer.stop()
        wsClient.finish()
    }
}
