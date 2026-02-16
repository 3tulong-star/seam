import Foundation

class RealtimeWSClient: NSObject, URLSessionWebSocketDelegate {
    private var webSocket: URLSessionWebSocketTask?
    var onPartialText: ((String) -> Void)?
    var onFinalText: ((String) -> Void)?
    
    func connect(url: URL, lang: String) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "model": "qwen3-asr-flash-realtime",
                "input_audio_format": "pcm",
                "sample_rate": 16000,
                "input_audio_transcription": ["language": lang]
            ]
        ]
        sendJSON(sessionUpdate)
        receiveMessage()
    }
    
    func sendAudio(base64: String) {
        sendJSON(["type": "input_audio_buffer.append", "audio": base64])
    }
    
    func finish() {
        sendJSON(["type": "input_audio_buffer.commit"])
        sendJSON(["type": "session.finish"])
    }
    
    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }
        webSocket?.send(.string(str)) { _ in }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            if case .success(.string(let text)) = result {
                self?.handleMessage(text)
                self?.receiveMessage()
            }
        }
    }
    
    private func handleMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        if type == "conversation.item.input_audio_transcription.text" {
            let text = (json["text"] as? String ?? "") + (json["stash"] as? String ?? "")
            DispatchQueue.main.async { self.onPartialText?(text) }
        } else if type == "conversation.item.input_audio_transcription.completed" {
            let transcript = json["transcript"] as? String ?? ""
            DispatchQueue.main.async { self.onFinalText?(transcript) }
        }
    }
}
