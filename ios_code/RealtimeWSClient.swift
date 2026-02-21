import Foundation

struct RealtimeConfig {
    let mode: String      // "dual_button" | "single_button" | "live"
    let leftLang: String  // e.g. "zh"
    let rightLang: String // e.g. "en"
}

final class RealtimeWSClient: NSObject, URLSessionWebSocketDelegate {
    private var task: URLSessionWebSocketTask?
    private var session: URLSession?

    // 兼容回调
    var onPartialText: ((String) -> Void)?
    var onFinalText: ((String) -> Void)?

    // 新增：回传完整事件，给 single_button / live 用
    var onPartialEvent: (([String: Any]) -> Void)?
    var onFinalEvent: (([String: Any]) -> Void)?

    var onError: ((String) -> Void)?

    // Debug: 打印原始 WS JSON
    var debugLogRawMessages: Bool = false

    func connect(url: URL, config: RealtimeConfig) {
        disconnect()

        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        let s = URLSession(configuration: cfg, delegate: self, delegateQueue: OperationQueue())
        session = s

        let t = s.webSocketTask(with: url)
        task = t
        t.resume()

        // 首条消息: session.update，带上 UI 模式和左右语言
        let msg: [String: Any] = [
            "type": "session.update",
            "session": [
                "model": "qwen3-asr-flash-realtime",
                "input_audio_format": "pcm",
                "sample_rate": 16000,
                // 让服务端/ASR自动识别语言，不在这里传 language
                "turn_detection": NSNull(), // manual 模式
                "mode": config.mode,
                "left_lang": config.leftLang,
                "right_lang": config.rightLang
            ]
        ]
        sendJSON(msg)
        receiveLoop()
    }

    func sendAudio(base64: String) {
        sendJSON(["type": "input_audio_buffer.append", "audio": base64])
    }

    func finish() {
        sendJSON(["type": "input_audio_buffer.commit"])
        sendJSON(["type": "session.finish"])
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let task else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }
        task.send(.string(str)) { _ in }
    }

    private func receiveLoop() {
        guard let task else { return }
        task.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                if case .string(let s) = message {
                    if self.debugLogRawMessages {
                        print("[WS IN]", s)
                    }
                    self.handleInbound(s)
                }
                self.receiveLoop()
            case .failure(let err):
                self.onError?("ws receive error: \(err.localizedDescription)")
            }
        }
    }

    private func handleInbound(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = obj["type"] as? String else { return }

        if type == "conversation.item.input_audio_transcription.text" {
            let text = (obj["text"] as? String ?? "") + (obj["stash"] as? String ?? "")
            onPartialText?(text)
            onPartialEvent?(obj)
        } else if type == "conversation.item.input_audio_transcription.completed" {
            let transcript = obj["transcript"] as? String ?? ""
            onFinalText?(transcript)
            onFinalEvent?(obj)
        } else if type == "error" {
            if let e = obj["error"] as? [String: Any] {
                onError?(e["message"] as? String ?? "ws error")
            } else {
                onError?("ws error")
            }
        } else {
            onPartialEvent?(obj)
        }
    }
}
