import SwiftUI

struct ModeSelectionView: View {
    @Binding var selectedMode: ConversationMode?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("选择模式")
                    .font(.title)
                    .padding(.top, 40)

                Button {
                    selectedMode = .dualButton
                } label: {
                    Text("双按钮模式（A/B）")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    selectedMode = .singleButton
                } label: {
                    Text("单按钮模式（自动识别语言）")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}
