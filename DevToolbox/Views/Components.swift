import SwiftUI

/// 复制按钮：点击后写入系统剪贴板，文字变「已复制 ✓」1.5 秒；
/// 用 token 防止连续点击时旧计时器提前清除新反馈
struct CopyButton: View {
    let text: String
    @State private var copied = false
    @State private var copyToken = UUID()

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            copied = true
            let token = UUID()
            copyToken = token
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard copyToken == token else { return }
                copied = false
            }
        } label: {
            Text(copied ? "已复制 ✓" : "复制")
        }
        .buttonStyle(.bordered)
    }
}

/// 多行输入区：标题 + 等宽 TextEditor（限高，内部滚动，防止外层页面被撑爆）
struct InputSection: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 80, maxHeight: 220)
                .padding(4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
        }
    }
}

/// 结果区：成功显示等宽文本 + 复制按钮，失败显示红色错误文案，nil 显示占位
struct OutputSection: View {
    let title: String
    let result: Result<String, ToolError>?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if case .success(let text)? = result {
                    CopyButton(text: text)
                }
            }
            switch result {
            case nil:
                Text("—")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            case .success(let text)?:
                ScrollView {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 40, maxHeight: 160)
            case .failure(let error)?:
                Text(error.userMessage)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
