import SwiftUI

struct JWTView: View {
    @State private var token = ""

    private var parsed: Result<JWTTool.ParsedJWT, ToolError>? {
        token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : JWTTool.parse(token)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InputSection(title: "粘贴 JWT Token", text: $token)
                Text("签名未验证，内容可被伪造，请勿据此信任 Token")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                switch parsed {
                case nil:
                    Text("输入 token 后自动解析")
                        .foregroundStyle(.secondary)
                case .failure(let error):
                    Text(error.userMessage)
                        .foregroundStyle(.red)
                case .success(let jwt):
                    OutputSection(title: "Header", result: .success(jwt.headerJSON))
                    OutputSection(title: "Payload", result: .success(jwt.payloadJSON))
                    if !jwt.timeAnnotations.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("时间字段").font(.headline)
                            ForEach(jwt.timeAnnotations, id: \.key) { annotation in
                                Text("\(annotation.key) → \(annotation.readable)")
                                    .monospacedDigit()
                            }
                        }
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                    if let expiryText = jwt.expiryText {
                        Text(expiryText)
                            .font(.title3)
                            .foregroundStyle(jwt.expired ? Color.red : Color.green)
                    }
                }
            }
            .padding(20)
        }
    }
}
