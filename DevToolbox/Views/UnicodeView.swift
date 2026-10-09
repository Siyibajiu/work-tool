import SwiftUI

struct UnicodeView: View {
    @State private var input = ""
    @State private var output: Result<String, ToolError>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InputSection(title: "输入内容", text: $input)
                HStack {
                    Button("中文 → Unicode") {
                        output = .success(UnicodeTool.toUnicode(input))
                    }
                    .disabled(input.isEmpty)
                    .buttonStyle(.bordered)
                    Button("Unicode → 中文") {
                        output = UnicodeTool.toChinese(input)
                    }
                    .disabled(input.isEmpty)
                    .buttonStyle(.bordered)
                    if case .success(let text)? = output {
                        Button("↑ 交换到输入") {
                            input = text
                            output = nil
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                }
                OutputSection(title: "结果", result: output)
            }
            .padding(20)
        }
    }
}
