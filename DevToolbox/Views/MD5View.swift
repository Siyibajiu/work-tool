import SwiftUI

struct MD5View: View {
    @State private var input = ""
    @State private var uppercase = false

    private var result: Result<String, ToolError>? {
        input.isEmpty ? nil : .success(MD5Tool.hex(input, uppercase: uppercase))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InputSection(title: "输入文本（支持多行）", text: $input)
                Toggle("大写输出", isOn: $uppercase)
                OutputSection(title: "MD5（32 位十六进制）", result: result)
            }
            .padding(20)
        }
    }
}
