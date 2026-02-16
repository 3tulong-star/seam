import SwiftUI

struct ContentView: View {
    @StateObject var vm = ConversationViewModel()
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(vm.messages, id: \.self) { msg in
                        Text(msg)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    if !vm.partialText.isEmpty {
                        Text(vm.partialText)
                            .foregroundColor(.gray)
                            .italic()
                            .padding()
                    }
                }
            }
            Spacer()
            Button(action: {}) {
                Text(vm.isRecording ? "正在听..." : "按住说话")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
                if pressing {
                    vm.start()
                } else {
                    vm.stop()
                }
            }, perform: {})
        }
        .padding()
    }
}
