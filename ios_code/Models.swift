import Foundation

enum Side {
    case a
    case b
}

enum ConversationMode {
    case dualButton   // A/B 双按钮模式
    case singleButton // 单按钮模式（ASR 自动识别语言）
}

struct LangOption: Identifiable, Equatable, Hashable {
    let id: String      // 语言 code, 例如 "zh"
    let name: String    // 展示名, 例如 "中文"
    let holdToTalkText: String // 按住说话的本地化文本
}

let supportedLangs: [LangOption] = [
    .init(id: "zh", name: "中文", holdToTalkText: "按住说话"),
    .init(id: "en", name: "English", holdToTalkText: "Hold to Talk"),
    .init(id: "ja", name: "日本語", holdToTalkText: "押して话す"),
    .init(id: "ko", name: "한국어", holdToTalkText: "누르고 말하기")
]

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    var side: Side
    var originalPartial: String
    var originalFinal: String?
    var translated: String?

    init(side: Side) {
        self.id = UUID()
        self.side = side
        self.originalPartial = ""
        self.originalFinal = nil
        self.translated = nil
    }
}
