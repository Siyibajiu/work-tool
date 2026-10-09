import Foundation

enum JWTTool {
    struct TimeAnnotation: Equatable {
        let key: String      // "exp" / "nbf" / "iat"
        let readable: String // 可读时间
    }

    struct ParsedJWT: Equatable {
        let headerJSON: String
        let payloadJSON: String
        let timeAnnotations: [TimeAnnotation]
        let expiryText: String? // "已过期 xx" / "剩余 xx"，无 exp 时为 nil
        let expired: Bool
    }

    static func parse(
        _ token: String,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Result<ParsedJWT, ToolError> {
        let parts = token
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".")
        guard parts.count == 3 else {
            return .failure(.invalidJWT("应含 3 段，实际 \(parts.count) 段"))
        }
        guard let headerData = base64URLDecode(String(parts[0])),
              let payloadData = base64URLDecode(String(parts[1])) else {
            return .failure(.invalidJWT("Base64 解码失败"))
        }
        guard let headerObj = (try? JSONSerialization.jsonObject(with: headerData)) as? [String: Any],
              let payloadObj = (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any],
              let headerJSON = prettyJSON(headerObj),
              let payloadJSON = prettyJSON(payloadObj) else {
            return .failure(.invalidJWT("JSON 解析失败"))
        }

        // 时间字段注释（数值型声明才注释；超出来世（|v|>1e12 秒）的荒谬值跳过）
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var annotations: [TimeAnnotation] = []
        for key in ["iat", "nbf", "exp"] {
            if let value = claimNumber(payloadObj[key]), value.magnitude <= 1e12 {
                annotations.append(
                    TimeAnnotation(key: key, readable: formatter.string(from: Date(timeIntervalSince1970: value)))
                )
            }
        }

        // 过期状态（RFC 7519：now >= exp 即视为过期）
        var expired = false
        var expiryText: String? = nil
        if let exp = claimNumber(payloadObj["exp"]) {
            let expDate = Date(timeIntervalSince1970: exp)
            expired = expDate <= now
            expiryText = (expired ? "已过期 " : "剩余 ") + humanize(abs(expDate.timeIntervalSince(now)))
        }

        return .success(
            ParsedJWT(
                headerJSON: headerJSON,
                payloadJSON: payloadJSON,
                timeAnnotations: annotations,
                expiryText: expiryText,
                expired: expired
            )
        )
    }

    /// base64url → Data
    static func base64URLDecode(_ input: String) -> Data? {
        var base64 = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return Data(base64Encoded: base64)
    }

    private static func prettyJSON(_ obj: Any) -> String? {
        guard let data = try? JSONSerialization.data(
            withJSONObject: obj,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        ), let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    /// 声明值取数：Double 直取，数字字符串（如 "4102444800"）也接受
    private static func claimNumber(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let s = value as? String { return Double(s) }
        return nil
    }

    /// 人性化时长；全程在 Double 空间比较，天数封顶 1e9，杜绝 Int 溢出崩溃
    private static func humanize(_ interval: TimeInterval) -> String {
        if interval < 60 { return "\(Int(interval)) 秒" }
        if interval < 3600 { return "\(Int(interval / 60)) 分钟" }
        if interval < 86400 { return "\(Int(interval / 3600)) 小时" }
        return "\(Int(min(interval / 86400, 1e9))) 天"
    }
}
