import Foundation

enum UnicodeTool {
    /// 中文 → Unicode：BMP 字符输出 \uXXXX（小写），超出 BMP 输出 U+XXXXXX，ASCII 原样保留
    static func toUnicode(_ input: String) -> String {
        var out = ""
        for scalar in input.unicodeScalars {
            if scalar.isASCII {
                out.unicodeScalars.append(scalar)
            } else if scalar.value <= 0xFFFF {
                out += String(format: "\\u%04x", scalar.value)
            } else {
                out += String(format: "U+%06X", scalar.value)
            }
        }
        return out
    }

    /// Unicode → 中文：识别 \uXXXX（恰好 4 位十六进制）与 U+XXXX（4~6 位十六进制），
    /// 其余字符原样保留；非法序列返回 .failure
    static func toChinese(_ input: String) -> Result<String, ToolError> {
        let chars = Array(input)
        var result = ""
        var i = 0

        while i < chars.count {
            // \uXXXX
            if chars[i] == "\\", i + 1 < chars.count, chars[i + 1] == "u" {
                guard i + 5 < chars.count else {
                    return .failure(.invalidUnicodeSequence(String(chars[i...])))
                }
                let hex = String(chars[(i + 2)...(i + 5)])
                guard let value = UInt32(hex, radix: 16),
                      let scalar = Unicode.Scalar(value) else {
                    return .failure(.invalidUnicodeSequence("\\u\(hex)"))
                }
                result.unicodeScalars.append(scalar)
                i += 6
                continue
            }
            // U+XXXX（4~6 位）
            if chars[i] == "U", i + 1 < chars.count, chars[i + 1] == "+" {
                var hex = ""
                var j = i + 2
                while j < chars.count, hex.count < 6, chars[j].isHexDigit {
                    hex.append(chars[j])
                    j += 1
                }
                guard hex.count >= 4,
                      let value = UInt32(hex, radix: 16),
                      let scalar = Unicode.Scalar(value) else {
                    return .failure(.invalidUnicodeSequence("U+\(hex)"))
                }
                result.unicodeScalars.append(scalar)
                // 跳过 U+ 序列之后的空白分隔符（如 "U+4F60 U+597D" → "你好"）
                while j < chars.count, chars[j] == " " || chars[j] == "\t" {
                    j += 1
                }
                i = j
                continue
            }
            result.append(chars[i])
            i += 1
        }
        return .success(result)
    }
}
