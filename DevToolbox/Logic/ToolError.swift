import Foundation

enum ToolError: Error, Equatable {
    case invalidTimestamp
    case invalidFormatTemplate
    case invalidJWT(String)
    case invalidURLFormat
    case invalidUnicodeSequence(String)

    var userMessage: String {
        switch self {
        case .invalidTimestamp:
            return "不是合法的时间戳（支持 10 位秒或 13 位毫秒）"
        case .invalidFormatTemplate:
            return "不是合法的日期格式模板"
        case .invalidJWT(let reason):
            return "不是合法的 JWT：\(reason)"
        case .invalidURLFormat:
            return "包含非法的 % 编码序列"
        case .invalidUnicodeSequence(let seq):
            return "包含非法的 Unicode 序列：\(seq)"
        }
    }
}
