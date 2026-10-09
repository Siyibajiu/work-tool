import Foundation

enum URLTool {
    /// RFC 3986 编码：仅保留无保留字符 A-Za-z0-9-._~，其余转 %XX
    static func encode(_ input: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return input.addingPercentEncoding(withAllowedCharacters: allowed) ?? input
    }

    /// 解码，非法 % 序列返回 .failure
    static func decode(_ input: String) -> Result<String, ToolError> {
        guard let decoded = input.removingPercentEncoding else {
            return .failure(.invalidURLFormat)
        }
        return .success(decoded)
    }
}
