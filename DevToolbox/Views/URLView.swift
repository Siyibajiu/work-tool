import SwiftUI

struct URLView: View {
    @State private var input = ""
    @State private var output: Result<String, ToolError>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InputSection(title: "输入内容", text: $input)
                HStack {
                    Button("编码") {
                        output = .success(URLTool.encode(input))
                    }
                    Button("解码") {
                        output = URLTool.decode(input)
                    }
                    if case .success(let text)? = output {
                        Button("↑ 交换到输入") {
                            input = text
                            output = nil
                        }
                    }
                    Spacer()
                }
                OutputSection(title: "结果", result: output)
            }
            .padding(20)
        }
    }
}
