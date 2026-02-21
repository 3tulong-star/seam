import SwiftUI

struct ContentView: View {
    @StateObject private var vm: ConversationViewModel
    
    init(mode: ConversationMode) {
        let viewModel = ConversationViewModel()
        viewModel.mode = mode
        _vm = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Chat Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(vm.messages) { message in
                            MessageBubble(message: message) {
                                vm.speakMessage(message)
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { oldValue, newValue in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: vm.messages.last?.originalPartial) { oldValue, newValue in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: vm.messages.last?.translated) { oldValue, newValue in
                    scrollToBottom(proxy: proxy)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // Footer
            footerView
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(vm.mode == .dualButton ? "双按钮模式" : "单按钮模式")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    vm.autoSpeak.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: vm.autoSpeak ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        Text("Auto Speak")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Language Selector
            HStack(spacing: 0) {
                // Lang A Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    vm.showingPickerA = true
                }) {
                    HStack {
                        Text(vm.langA.name)
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .opacity(0.5)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .confirmationDialog("选择语言", isPresented: $vm.showingPickerA, titleVisibility: .visible) {
                    ForEach(supportedLangs) { lang in
                        Button(lang.name) {
                            vm.langA = lang
                        }
                    }
                }
                
                // Swap Button
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        vm.swapLanguages()
                    }
                }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 8)
                
                // Lang B Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    vm.showingPickerB = true
                }) {
                    HStack {
                        Text(vm.langB.name)
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .opacity(0.5)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .confirmationDialog("选择语言", isPresented: $vm.showingPickerB, titleVisibility: .visible) {
                    ForEach(supportedLangs) { lang in
                        Button(lang.name) {
                            vm.langB = lang
                        }
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var footerView: some View {
        VStack(spacing: 0) {
            if vm.mode == .dualButton {
                HStack(spacing: 16) {
                    HoldButton(
                        title: vm.langA.holdToTalkText,
                        isHolding: vm.isHoldingA,
                        color: Color(UIColor.systemGray2),
                        activeColor: Color(UIColor.systemGray)
                    ) { pressing in
                        vm.pressAChanged(pressing)
                    }
                    
                    HoldButton(
                        title: vm.langB.holdToTalkText,
                        isHolding: vm.isHoldingB,
                        color: .blue,
                        activeColor: Color(UIColor.systemBlue).opacity(0.8)
                    ) { pressing in
                        vm.pressBChanged(pressing)
                    }
                }
                .padding(.horizontal)
            } else {
                // 单按钮模式
                HoldButton(
                    title: "按住说话",
                    isHolding: vm.isHoldingSingle,
                    color: .blue,
                    activeColor: Color(UIColor.systemBlue).opacity(0.8)
                ) { pressing in
                    vm.singlePressChanged(pressing)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = vm.messages.last else { return }
        withAnimation {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let onPlay: () -> Void
    
    var body: some View {
        HStack {
            if message.side == .b { Spacer(minLength: 60) }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.originalFinal ?? message.originalPartial)
                    .font(.system(size: 13))
                    .opacity(0.7)
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text(message.translated ?? (message.originalFinal != nil ? "..." : ""))
                        .font(.system(size: 16))
                    
                    if message.translated != nil {
                        Button(action: onPlay) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(message.side == .b ? .white : .blue)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleColor)
            .foregroundColor(textColor)
            .cornerRadius(18)
            
            if message.side == .a { Spacer(minLength: 60) }
        }
    }
    
    private var bubbleColor: Color {
        message.side == .a ? Color(UIColor.secondarySystemGroupedBackground) : Color.blue
    }
    
    private var textColor: Color {
        message.side == .a ? .primary : .white
    }
}

struct HoldButton: View {
    let title: String
    let isHolding: Bool
    let color: Color
    let activeColor: Color
    let onPressingChanged: (Bool) -> Void
    
    var body: some View {
        Text(isHolding ? "正在听..." : title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isHolding ? activeColor : color)
            .cornerRadius(27)
            .scaleEffect(isHolding ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isHolding)
            .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
                onPressingChanged(pressing)
            }, perform: {})
    }
}
