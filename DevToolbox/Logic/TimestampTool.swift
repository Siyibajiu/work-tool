import Foundation

enum TimestampTool {
    /// 自动识别 10 位（秒）/ 13 位（毫秒）时间戳
    static func date(fromTimestamp input: String) -> Result<Date, ToolError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.allSatisfy(\.isNumber),
              let value = UInt64(trimmed) else {
            return .failure(.invalidTimestamp)
        }
        let seconds: Double
        switch trimmed.count {
        case 10:
            seconds = Double(value)
        case 13:
            seconds = Double(value) / 1000
        default:
            return .failure(.invalidTimestamp)
        }
        return .success(Date(timeIntervalSince1970: seconds))
    }

    /// Date → (秒级字符串, 毫秒级字符串)；Int64 承载负值，1970 前的日期安全
    static func timestampStrings(from date: Date) -> (seconds: String, millis: String) {
        let seconds = Int64(date.timeIntervalSince1970.rounded(.down))
        let millis = Int64((date.timeIntervalSince1970 * 1000).rounded())
        return (String(seconds), String(millis))
    }

    /// 模板仅允许 ASCII 字母 y M d H m s S E a，其余字符（含中文、标点）视为字面量
    static func isValidTemplate(_ template: String) -> Bool {
        guard !template.isEmpty else { return false }
        let allowed = Set("yMdHmsSEa")
        return template.allSatisfy { ch in
            guard ch.isASCII, ch.isLetter else { return true }
            return allowed.contains(ch)
        }
    }

    /// 按时区与模板格式化，模板非法返回 .failure
    static func format(
        _ date: Date,
        timeZone: TimeZone,
        template: String
    ) -> Result<String, ToolError> {
        guard isValidTemplate(template) else {
            return .failure(.invalidFormatTemplate)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = template
        return .success(formatter.string(from: date))
    }
}
