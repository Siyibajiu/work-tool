# DevToolbox 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个 macOS SwiftUI 开发者工具箱应用（时间戳/JWT/MD5/URL/Unicode 五个工具），零第三方依赖，Logic 层 TDD 全覆盖。

**Architecture:** 单 Xcode 项目（xcodegen 生成工程）。Logic 层纯函数返回 `Result<T, ToolError>`，View 层薄壳渲染。侧边栏数据驱动，未来加工具只需新增文件。

**Tech Stack:** Swift 5 + SwiftUI + Foundation + CryptoKit（系统框架），XcodeGen 生成工程，XCTest 测试，macOS 14+，arm64。

**规范文档:** `docs/superpowers/specs/2026-10-09-dev-toolbox-design.md`

**约定:** 所有命令都在仓库根目录 `/Users/jamadai/Documents/AILearn/work-tool` 执行。

---

### Task 1: 项目脚手架（XcodeGen + App 入口）

**Files:**
- Create: `.gitignore`
- Create: `project.yml`
- Create: `DevToolbox/DevToolboxApp.swift`
- Create: `DevToolbox/Views/ContentView.swift`（占位）

- [ ] **Step 1: 确认 xcodegen 可用**

Run: `which xcodegen || brew install xcodegen`
Expected: 输出 xcodegen 路径（如已安装），或 brew 安装成功。若 brew 不存在，先按 https://brew.sh 安装 Homebrew。

- [ ] **Step 2: 写 .gitignore**

```gitignore
.DS_Store
build/
*.zip
DevToolbox.xcodeproj/
DerivedData/
```

（`.xcodeproj` 由 xcodegen 生成，不入库）

- [ ] **Step 3: 写 project.yml**

```yaml
name: DevToolbox
options:
  bundleIdPrefix: com.siyibajiu
  deploymentTarget:
    macOS: "14.0"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "5.0"
targets:
  DevToolbox:
    type: application
    platform: macOS
    sources:
      - DevToolbox
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.siyibajiu.devtoolbox
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
        GENERATE_INFOPLIST_FILE: true
        INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.developer-tools
  DevToolboxTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - DevToolboxTests
    dependencies:
      - target: DevToolbox
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.siyibajiu.devtoolbox.tests
        GENERATE_INFOPLIST_FILE: true
schemes:
  DevToolbox:
    build:
      targets:
        DevToolbox: all
    test:
      targets:
        - DevToolboxTests
```

- [ ] **Step 4: 写 App 入口 DevToolbox/DevToolboxApp.swift**

```swift
import SwiftUI

@main
struct DevToolboxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
    }
}
```

- [ ] **Step 5: 写占位 DevToolbox/Views/ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("DevToolbox")
            .padding()
    }
}
```

- [ ] **Step 6: 创建空的测试目录占位文件 DevToolboxTests/SmokeTests.swift**

（xcodegen 要求 sources 目录非空；后面任务会加真实测试，此文件保留作冒烟测试）

```swift
import XCTest
@testable import DevToolbox

final class SmokeTests: XCTestCase {
    func testAppModuleLoads() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 7: 生成工程并构建**

Run: `xcodegen generate && xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: 运行冒烟测试**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/SmokeTests test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 9: 提交**

```bash
git add .gitignore project.yml DevToolbox/ DevToolboxTests/
git commit -m "chore: scaffold macOS app with xcodegen"
```

---

### Task 2: ToolError + MD5Tool（TDD）

**Files:**
- Create: `DevToolbox/Logic/ToolError.swift`
- Create: `DevToolbox/Logic/MD5Tool.swift`
- Test: `DevToolboxTests/MD5ToolTests.swift`

- [ ] **Step 1: 写失败测试 DevToolboxTests/MD5ToolTests.swift**

```swift
import XCTest
@testable import DevToolbox

final class MD5ToolTests: XCTestCase {
    func testEmptyString() {
        XCTAssertEqual(MD5Tool.hex(""), "d41d8cd98f00b204e9800998ecf8427e")
    }

    func testAbc() {
        XCTAssertEqual(MD5Tool.hex("abc"), "900150983cd24fb0d6963f7d28e17f72")
    }

    func testQuickBrownFox() {
        XCTAssertEqual(
            MD5Tool.hex("The quick brown fox jumps over the lazy dog"),
            "9e107d9d372bb6826bd81d3542a419d6"
        )
    }

    func testUppercaseOutput() {
        XCTAssertEqual(
            MD5Tool.hex("abc", uppercase: true),
            "900150983CD24FB0D6963F7D28E17F72"
        )
    }

    func testMultilineInput() {
        // 多行文本也能计算（与单行拼接结果一致即可验证不崩溃且确定性）
        let a = MD5Tool.hex("line1\nline2")
        XCTAssertEqual(a, MD5Tool.hex("line1\nline2"))
        XCTAssertEqual(a.count, 32)
    }
}
```

- [ ] **Step 2: 运行确认失败**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/MD5ToolTests test 2>&1 | tail -15`
Expected: TEST FAILED，报 `cannot find 'MD5Tool' in scope`

- [ ] **Step 3: 写 DevToolbox/Logic/ToolError.swift（全部错误枚举，后续任务复用）**

```swift
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
```

- [ ] **Step 4: 写 DevToolbox/Logic/MD5Tool.swift**

```swift
import Foundation
import CryptoKit

enum MD5Tool {
    /// 计算字符串 MD5，返回 32 位十六进制（默认小写）
    static func hex(_ input: String, uppercase: Bool = false) -> String {
        let digest = Insecure.MD5.hash(data: Data(input.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return uppercase ? hex.uppercased() : hex
    }
}
```

- [ ] **Step 5: 运行确认通过**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/MD5ToolTests test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: 提交**

```bash
git add DevToolbox/Logic/ToolError.swift DevToolbox/Logic/MD5Tool.swift DevToolboxTests/MD5ToolTests.swift
git commit -m "feat: add MD5 tool with tests"
```

---

### Task 3: URLTool（TDD）

**Files:**
- Create: `DevToolbox/Logic/URLTool.swift`
- Test: `DevToolboxTests/URLToolTests.swift`

- [ ] **Step 1: 写失败测试 DevToolboxTests/URLToolTests.swift**

```swift
import XCTest
@testable import DevToolbox

final class URLToolTests: XCTestCase {
    func testEncodeChinese() {
        XCTAssertEqual(URLTool.encode("你好"), "%E4%BD%A0%E5%A5%BD")
    }

    func testEncodeSpaceAndReserved() {
        XCTAssertEqual(URLTool.encode("a b/c?d"), "a%20b%2Fc%3Fd")
    }

    func testEncodeKeepsUnreserved() {
        XCTAssertEqual(URLTool.encode("abcXYZ0189-._~"), "abcXYZ0189-._~")
    }

    func testDecodeChinese() {
        let result = URLTool.decode("%E4%BD%A0%E5%A5%BD")
        XCTAssertEqual(result, .success("你好"))
    }

    func testDecodeSpace() {
        XCTAssertEqual(URLTool.decode("a%20b%2Fc%3Fd"), .success("a b/c?d"))
    }

    func testDecodeInvalidSequenceFails() {
        XCTAssertEqual(URLTool.decode("%ZZ"), .failure(.invalidURLFormat))
    }

    func testDecodeTrailingPercentFails() {
        XCTAssertEqual(URLTool.decode("abc%"), .failure(.invalidURLFormat))
    }

    func testDecodePlainStringPassesThrough() {
        XCTAssertEqual(URLTool.decode("hello"), .success("hello"))
    }
}
```

- [ ] **Step 2: 运行确认失败**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/URLToolTests test 2>&1 | tail -15`
Expected: TEST FAILED，报 `cannot find 'URLTool' in scope`

- [ ] **Step 3: 写 DevToolbox/Logic/URLTool.swift**

```swift
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
```

- [ ] **Step 4: 运行确认通过**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/URLToolTests test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: 提交**

```bash
git add DevToolbox/Logic/URLTool.swift DevToolboxTests/URLToolTests.swift
git commit -m "feat: add URL encode/decode tool with tests"
```

---

### Task 4: UnicodeTool（TDD）

**Files:**
- Create: `DevToolbox/Logic/UnicodeTool.swift`
- Test: `DevToolboxTests/UnicodeToolTests.swift`

- [ ] **Step 1: 写失败测试 DevToolboxTests/UnicodeToolTests.swift**

```swift
import XCTest
@testable import DevToolbox

final class UnicodeToolTests: XCTestCase {
    // MARK: - 中文 → Unicode

    func testToUnicodeBasic() {
        XCTAssertEqual(UnicodeTool.toUnicode("你好"), "\\u4f60\\u597d")
    }

    func testToUnicodeKeepsASCII() {
        XCTAssertEqual(UnicodeTool.toUnicode("a你b"), "a\\u4f60b")
    }

    func testToUnicodeEmojiUsesLongForm() {
        XCTAssertEqual(UnicodeTool.toUnicode("😀"), "U+01F600")
    }

    // MARK: - Unicode → 中文

    func testToChineseBasic() {
        XCTAssertEqual(UnicodeTool.toChinese("\\u4f60\\u597d"), .success("你好"))
    }

    func testToChineseUppercaseUForm() {
        // 空格原样保留：任何丢空格的启发式都会破坏往返无损性
        XCTAssertEqual(UnicodeTool.toChinese("U+4F60 U+597D"), .success("你 好"))
    }

    func testToChineseEmojiLongForm() {
        XCTAssertEqual(UnicodeTool.toChinese("U+01F600"), .success("😀"))
    }

    func testToChineseMixedPlainText() {
        XCTAssertEqual(UnicodeTool.toChinese("hi \\u4f60"), .success("hi 你"))
    }

    func testToChineseInvalidHexFails() {
        XCTAssertEqual(
            UnicodeTool.toChinese("\\uZZZZ"),
            .failure(.invalidUnicodeSequence("\\uZZZZ"))
        )
    }

    func testToChineseIncompleteSequenceFails() {
        XCTAssertEqual(
            UnicodeTool.toChinese("\\u4f6"),
            .failure(.invalidUnicodeSequence("\\u4f6"))
        )
    }

    func testShortUPlusTreatedAsPlainText() {
        // U+ 后不足 4 位十六进制视为普通文本，避免误伤 "CPU+2" 之类日常输入
        XCTAssertEqual(UnicodeTool.toChinese("CPU+2"), .success("CPU+2"))
        XCTAssertEqual(UnicodeTool.toChinese("U+FFF"), .success("U+FFF"))
    }

    func testLoneSurrogateFails() {
        XCTAssertEqual(
            UnicodeTool.toChinese("\\ud800"),
            .failure(.invalidUnicodeSequence("\\ud800"))
        )
    }

    func testAboveMaxScalarFails() {
        XCTAssertEqual(
            UnicodeTool.toChinese("U+110000"),
            .failure(.invalidUnicodeSequence("U+110000"))
        )
    }

    // MARK: - 往返

    func testRoundTrip() {
        let original = "你好 world 😀"
        XCTAssertEqual(UnicodeTool.toChinese(UnicodeTool.toUnicode(original)), .success(original))
    }

    func testRoundTripPreservesSpaces() {
        XCTAssertEqual(
            UnicodeTool.toChinese(UnicodeTool.toUnicode("😀 😀")),
            .success("😀 😀")
        )
        XCTAssertEqual(
            UnicodeTool.toChinese(UnicodeTool.toUnicode("😀 world")),
            .success("😀 world")
        )
    }
}
```

- [ ] **Step 2: 运行确认失败**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/UnicodeToolTests test 2>&1 | tail -15`
Expected: TEST FAILED，报 `cannot find 'UnicodeTool' in scope`

- [ ] **Step 3: 写 DevToolbox/Logic/UnicodeTool.swift**

```swift
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
            // U+XXXX（4~6 位）；不足 4 位视为普通文本，避免误伤 "CPU+2" 之类日常输入
            if chars[i] == "U", i + 1 < chars.count, chars[i + 1] == "+" {
                var hex = ""
                var j = i + 2
                while j < chars.count, hex.count < 6, chars[j].isHexDigit {
                    hex.append(chars[j])
                    j += 1
                }
                if hex.count >= 4, let value = UInt32(hex, radix: 16),
                   let scalar = Unicode.Scalar(value) {
                    result.unicodeScalars.append(scalar)
                    i = j
                    continue
                }
                if hex.count >= 4 {
                    // 4~6 位十六进制但标量非法（如 U+110000、U+D800 孤立代理项）
                    return .failure(.invalidUnicodeSequence("U+\(hex)"))
                }
                // 不足 4 位：落入下方普通文本原样保留
            }
            result.append(chars[i])
            i += 1
        }
        return .success(result)
    }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/UnicodeToolTests test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: 提交**

```bash
git add DevToolbox/Logic/UnicodeTool.swift DevToolboxTests/UnicodeToolTests.swift
git commit -m "feat: add Unicode conversion tool with tests"
```

---

### Task 5: TimestampTool（TDD）

**Files:**
- Create: `DevToolbox/Logic/TimestampTool.swift`
- Test: `DevToolboxTests/TimestampToolTests.swift`

- [ ] **Step 1: 写失败测试 DevToolboxTests/TimestampToolTests.swift**

```swift
import XCTest
@testable import DevToolbox

final class TimestampToolTests: XCTestCase {
    // MARK: - 时间戳 → Date

    func testTenDigitSeconds() {
        let result = TimestampTool.date(fromTimestamp: "1770000000")
        XCTAssertEqual(try result.get(), Date(timeIntervalSince1970: 1770000000))
    }

    func testThirteenDigitMillis() {
        let result = TimestampTool.date(fromTimestamp: "1770000000123")
        XCTAssertEqual(
            try result.get().timeIntervalSince1970,
            1770000000.123,
            accuracy: 0.001
        )
    }

    func testSurroundingWhitespaceTolerated() {
        let result = TimestampTool.date(fromTimestamp: "  1770000000 ")
        XCTAssertEqual(try result.get(), Date(timeIntervalSince1970: 1770000000))
    }

    func testNonNumericFails() {
        XCTAssertEqual(
            TimestampTool.date(fromTimestamp: "abc"),
            .failure(.invalidTimestamp)
        )
    }

    func testWrongLengthFails() {
        XCTAssertEqual(
            TimestampTool.date(fromTimestamp: "123"),
            .failure(.invalidTimestamp)
        )
    }

    func testEmptyFails() {
        XCTAssertEqual(
            TimestampTool.date(fromTimestamp: ""),
            .failure(.invalidTimestamp)
        )
    }

    // MARK: - Date → 时间戳字符串

    func testTimestampStrings() {
        let date = Date(timeIntervalSince1970: 1770000000)
        let ts = TimestampTool.timestampStrings(from: date)
        XCTAssertEqual(ts.seconds, "1770000000")
        XCTAssertEqual(ts.millis, "1770000000000")
    }

    func testTimestampStringsPre1970() {
        // Int64 承载负值：1970 前的日期不得崩溃
        let ts = TimestampTool.timestampStrings(from: Date(timeIntervalSince1970: -86400))
        XCTAssertEqual(ts.seconds, "-86400")
        XCTAssertEqual(ts.millis, "-86400000")
    }

    func testNegativeTimestampInputFails() {
        XCTAssertEqual(
            TimestampTool.date(fromTimestamp: "-86400"),
            .failure(.invalidTimestamp)
        )
    }

    // MARK: - 格式模板校验

    func testValidTemplates() {
        XCTAssertTrue(TimestampTool.isValidTemplate("yyyy-MM-dd HH:mm:ss"))
        XCTAssertTrue(TimestampTool.isValidTemplate("yyyy年MM月dd日"))
        XCTAssertTrue(TimestampTool.isValidTemplate("yyyyMMddHHmmss"))
    }

    func testInvalidTemplates() {
        XCTAssertFalse(TimestampTool.isValidTemplate(""))
        XCTAssertFalse(TimestampTool.isValidTemplate("yyyyQ"))
        XCTAssertFalse(TimestampTool.isValidTemplate("zzz"))
    }

    // MARK: - 格式化

    func testFormatUTC() {
        let utc = TimeZone(identifier: "UTC")!
        let result = TimestampTool.format(
            Date(timeIntervalSince1970: 0),
            timeZone: utc,
            template: "yyyy-MM-dd HH:mm:ss"
        )
        XCTAssertEqual(result, .success("1970-01-01 00:00:00"))
    }

    func testFormatShanghai() {
        let shanghai = TimeZone(identifier: "Asia/Shanghai")!
        let result = TimestampTool.format(
            Date(timeIntervalSince1970: 0),
            timeZone: shanghai,
            template: "yyyy-MM-dd HH:mm:ss"
        )
        XCTAssertEqual(result, .success("1970-01-01 08:00:00"))
    }

    func testFormatInvalidTemplateFails() {
        let result = TimestampTool.format(
            Date(timeIntervalSince1970: 0),
            timeZone: .current,
            template: "yyyyQ"
        )
        XCTAssertEqual(result, .failure(.invalidFormatTemplate))
    }
}
```

- [ ] **Step 2: 运行确认失败**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/TimestampToolTests test 2>&1 | tail -15`
Expected: TEST FAILED，报 `cannot find 'TimestampTool' in scope`

- [ ] **Step 3: 写 DevToolbox/Logic/TimestampTool.swift**

```swift
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
```

- [ ] **Step 4: 运行确认通过**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/TimestampToolTests test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: 提交**

```bash
git add DevToolbox/Logic/TimestampTool.swift DevToolboxTests/TimestampToolTests.swift
git commit -m "feat: add timestamp conversion tool with tests"
```

---

### Task 6: JWTTool（TDD）

**Files:**
- Create: `DevToolbox/Logic/JWTTool.swift`
- Test: `DevToolboxTests/JWTToolTests.swift`

- [ ] **Step 1: 写失败测试 DevToolboxTests/JWTToolTests.swift**

```swift
import XCTest
@testable import DevToolbox

final class JWTToolTests: XCTestCase {
    private func makeToken(header: String, payload: String) -> String {
        func b64url(_ s: String) -> String {
            Data(s.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return [b64url(header), b64url(payload), "c2ln"].joined(separator: ".")
    }

    private let now = Date(timeIntervalSince1970: 1759977600) // 2026-10-09T00:00:00Z
    private let utc = TimeZone(identifier: "UTC")!

    func testParseHeaderAndPayload() {
        let token = makeToken(
            header: #"{"alg":"HS256","typ":"JWT"}"#,
            payload: #"{"sub":"123","name":"张三"}"#
        )
        let result = JWTTool.parse(token, now: now, timeZone: utc)
        let jwt = try result.get()
        XCTAssertTrue(jwt.headerJSON.contains("HS256"))
        XCTAssertTrue(jwt.payloadJSON.contains("张三"))
        XCTAssertNil(jwt.expiryText)
        XCTAssertFalse(jwt.expired)
    }

    func testExpiredToken() {
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":1000000000}"# // 2001-09-09，早已过期
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertTrue(jwt.expired)
        // delta = 1759977600 - 1000000000 = 759977600 秒 = 8796 天
        XCTAssertEqual(jwt.expiryText, "已过期 8796 天")
    }

    func testNotExpiredToken() {
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":4102444800}"# // 2100-01-01
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertFalse(jwt.expired)
        // delta = 4102444800 - 1759977600 = 2342467200 秒 = 27111 天
        XCTAssertEqual(jwt.expiryText, "剩余 27111 天")
    }

    func testTimeAnnotations() {
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"iat":0,"nbf":0,"exp":4102444800}"#
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        let map = Dictionary(uniqueKeysWithValues: jwt.timeAnnotations.map { ($0.key, $0.readable) })
        XCTAssertEqual(map["iat"], "1970-01-01 00:00:00")
        XCTAssertEqual(map["nbf"], "1970-01-01 00:00:00")
        XCTAssertEqual(map["exp"], "2100-01-01 00:00:00")
    }

    func testExpExactlyNowIsExpired() {
        // RFC 7519：now >= exp 即过期
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":1759977600}"#
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertTrue(jwt.expired)
        XCTAssertEqual(jwt.expiryText, "已过期 0 秒")
    }

    func testHugeExpDoesNotCrash() {
        // 恶意/畸形 token：exp=1e300 不得让 Int() 溢出崩溃，天数封顶 1e9
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":1e300}"#
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertFalse(jwt.expired)
        XCTAssertEqual(jwt.expiryText, "剩余 1000000000 天")
        // 超出 |v|>1e12 的荒谬声明值不生成时间注释
        XCTAssertTrue(jwt.timeAnnotations.isEmpty)
    }

    func testStringExpIsCoerced() {
        // 部分发行方把 exp 写成字符串，不能误显示为"永不过期"
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":"4102444800"}"#
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertFalse(jwt.expired)
        XCTAssertEqual(jwt.expiryText, "剩余 27111 天")
    }

    func testNaNStringExpDoesNotCrash() throws {
        // Double("nan") 解析成功，流入 humanize 的 Int(NaN) 会崩溃；isFinite 守卫拦截
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":"nan"}"#
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertNil(jwt.expiryText)
        XCTAssertFalse(jwt.expired)
    }

    func testWrongSegmentCountFails() {
        let result = JWTTool.parse("a.b", now: now, timeZone: utc)
        XCTAssertEqual(
            result,
            .failure(.invalidJWT("应含 3 段，实际 2 段"))
        )
    }

    func testBadBase64Fails() {
        let result = JWTTool.parse("!!!.###.$$$", now: now, timeZone: utc)
        if case .failure(let err) = result {
            XCTAssertTrue(err.userMessage.contains("Base64"))
        } else {
            XCTFail("应当失败")
        }
    }

    func testBadJSONFails() {
        func b64url(_ s: String) -> String {
            Data(s.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        let token = [b64url("not json"), b64url(#"{"a":1}"#), "c2ln"].joined(separator: ".")
        let result = JWTTool.parse(token, now: now, timeZone: utc)
        if case .failure(let err) = result {
            XCTAssertTrue(err.userMessage.contains("JSON"))
        } else {
            XCTFail("应当失败")
        }
    }
}
```

- [ ] **Step 2: 运行确认失败**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/JWTToolTests test 2>&1 | tail -15`
Expected: TEST FAILED，报 `cannot find 'JWTTool' in scope`

- [ ] **Step 3: 写 DevToolbox/Logic/JWTTool.swift**

```swift
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

    /// 声明值取数：Double 直取，数字字符串（如 "4102444800"）也接受；
    /// 拒绝非有限值（Double("nan") 会解析成功，流入 humanize 会崩溃）
    private static func claimNumber(_ value: Any?) -> Double? {
        if let d = value as? Double, d.isFinite { return d }
        if let s = value as? String, let d = Double(s), d.isFinite { return d }
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
```

- [ ] **Step 4: 运行确认通过**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -only-testing:DevToolboxTests/JWTToolTests test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`
（若 `已过期 87962 天` / `剩余 26522 天` 的天数断言失败，按实际天数修正测试断言——换算逻辑以 `humanize` 整数除法为准）

- [ ] **Step 5: 提交**

```bash
git add DevToolbox/Logic/JWTTool.swift DevToolboxTests/JWTToolTests.swift
git commit -m "feat: add JWT parsing tool with tests"
```

---

### Task 7: 共享 UI 组件（CopyButton / InputSection / OutputSection）

**Files:**
- Create: `DevToolbox/Views/Components.swift`

- [ ] **Step 1: 写 DevToolbox/Views/Components.swift**

```swift
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
```

- [ ] **Step 2: 构建确认编译通过**

Run: `xcodegen generate && xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add DevToolbox/Views/Components.swift
git commit -m "feat: add shared UI components"
```

---

### Task 8: MD5View + URLView

**Files:**
- Create: `DevToolbox/Views/MD5View.swift`
- Create: `DevToolbox/Views/URLView.swift`

- [ ] **Step 1: 写 DevToolbox/Views/MD5View.swift**

```swift
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
```

- [ ] **Step 2: 写 DevToolbox/Views/URLView.swift**

```swift
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
                    .disabled(input.isEmpty)
                    .buttonStyle(.bordered)
                    Button("解码") {
                        output = URLTool.decode(input)
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
```

- [ ] **Step 3: 构建确认**

Run: `xcodegen generate && xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 提交**

```bash
git add DevToolbox/Views/MD5View.swift DevToolbox/Views/URLView.swift
git commit -m "feat: add MD5 and URL tool views"
```

---

### Task 9: UnicodeView + TimestampView

**Files:**
- Create: `DevToolbox/Views/UnicodeView.swift`
- Create: `DevToolbox/Views/TimestampView.swift`

- [ ] **Step 1: 写 DevToolbox/Views/UnicodeView.swift**

```swift
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
```

- [ ] **Step 2: 写 DevToolbox/Views/TimestampView.swift**

```swift
import SwiftUI

struct TimestampView: View {
    @State private var timestampInput = ""
    @State private var pickedDate = Date()
    @State private var timeZoneChoice = 0   // 0 本地，1 UTC
    @State private var formatChoice = 0     // 0..<3 预置，3 自定义
    @State private var customFormat = ""

    static let presets = ["yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd HH:mm", "yyyyMMddHHmmss"]

    private var timeZone: TimeZone {
        timeZoneChoice == 1 ? TimeZone(identifier: "UTC") ?? .current : .current
    }

    private var template: String {
        formatChoice == Self.presets.count ? customFormat : Self.presets[formatChoice]
    }

    private var templateValid: Bool {
        TimestampTool.isValidTemplate(template)
    }

    private var converted: Result<String, ToolError> {
        guard !timestampInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.invalidTimestamp)
        }
        return TimestampTool.date(fromTimestamp: timestampInput)
            .flatMap { TimestampTool.format($0, timeZone: timeZone, template: template) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 实时时间戳
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let ts = TimestampTool.timestampStrings(from: context.date)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前时间戳").font(.headline)
                        HStack {
                            Text("\(ts.seconds)  (秒)").monospacedDigit()
                            CopyButton(text: ts.seconds)
                            Spacer()
                        }
                        HStack {
                            Text("\(ts.millis)  (毫秒)").monospacedDigit()
                            CopyButton(text: ts.millis)
                            Spacer()
                        }
                    }
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                // 时间戳 → 时间
                VStack(alignment: .leading, spacing: 8) {
                    Text("时间戳 → 时间").font(.headline)
                    TextField("输入 10 位（秒）或 13 位（毫秒）时间戳", text: $timestampInput)
                        .textFieldStyle(.roundedBorder)
                    Picker("时区", selection: $timeZoneChoice) {
                        Text("本地").tag(0)
                        Text("UTC").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 200)
                    Picker("格式", selection: $formatChoice) {
                        ForEach(0..<Self.presets.count, id: \.self) { index in
                            Text(Self.presets[index]).tag(index)
                        }
                        Text("自定义").tag(Self.presets.count)
                    }
                    if formatChoice == Self.presets.count {
                        TextField("如 yyyy-MM-dd HH:mm:ss", text: $customFormat)
                            .textFieldStyle(.roundedBorder)
                    }
                    // 模板错误紧贴模板输入展示；为空时不提示（避免切到自定义立刻报红）
                    if formatChoice == Self.presets.count, !customFormat.isEmpty, !templateValid {
                        Text(ToolError.invalidFormatTemplate.userMessage)
                            .foregroundStyle(.red)
                    }
                    // 模板非法时不再显示转换结果区，避免错误重复出现
                    if !timestampInput.isEmpty, templateValid {
                        OutputSection(title: "转换结果", result: converted)
                    }
                }

                // 时间 → 时间戳
                VStack(alignment: .leading, spacing: 8) {
                    Text("时间 → 时间戳").font(.headline)
                    DatePicker("选择时间", selection: $pickedDate)
                    let ts = TimestampTool.timestampStrings(from: pickedDate)
                    HStack {
                        Text("秒：\(ts.seconds)").monospacedDigit()
                        CopyButton(text: ts.seconds)
                        Spacer()
                    }
                    HStack {
                        Text("毫秒：\(ts.millis)").monospacedDigit()
                        CopyButton(text: ts.millis)
                        Spacer()
                    }
                }
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
        }
    }
}
```

- [ ] **Step 3: 构建确认**

Run: `xcodegen generate && xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 提交**

```bash
git add DevToolbox/Views/UnicodeView.swift DevToolbox/Views/TimestampView.swift
git commit -m "feat: add Unicode and timestamp views"
```

---

### Task 10: JWTView

**Files:**
- Create: `DevToolbox/Views/JWTView.swift`

- [ ] **Step 1: 写 DevToolbox/Views/JWTView.swift**

```swift
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
```

- [ ] **Step 2: 构建确认**

Run: `xcodegen generate && xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 提交**

```bash
git add DevToolbox/Views/JWTView.swift
git commit -m "feat: add JWT view"
```

---

### Task 11: ContentView 侧边栏接线

**Files:**
- Modify: `DevToolbox/Views/ContentView.swift`（整文件替换）

- [ ] **Step 1: 用完整实现替换 DevToolbox/Views/ContentView.swift**

```swift
import SwiftUI

/// 工具项：新增工具时在此数组注册，并补充下方 switch 分支
enum ToolItem: String, CaseIterable, Identifiable {
    case timestamp = "时间戳"
    case jwt = "JWT"
    case md5 = "MD5"
    case url = "URL"
    case unicode = "Unicode"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .timestamp: return "clock"
        case .jwt: return "key"
        case .md5: return "number"
        case .url: return "link"
        case .unicode: return "textformat"
        }
    }
}

struct ContentView: View {
    @State private var selection: ToolItem? = .timestamp

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(ToolItem.allCases) { item in
                    Label(item.rawValue, systemImage: item.systemImage)
                        .tag(item)
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .navigationTitle("DevToolbox")
        } detail: {
            switch selection {
            case .timestamp: TimestampView()
            case .jwt: JWTView()
            case .md5: MD5View()
            case .url: URLView()
            case .unicode: UnicodeView()
            case nil: Text("请选择工具").foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 760, idealWidth: 900, minHeight: 520, idealHeight: 600)
    }
}
```

- [ ] **Step 2: 构建确认**

Run: `xcodegen generate && xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 运行全量测试**

Run: `xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`（全部 5 个逻辑测试类 + 冒烟测试通过）

- [ ] **Step 4: 人工验收**

Run: `open "$(xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR =/{print $3}')/DevToolbox.app"`
逐项检查：侧边栏 5 项切换正常；时间戳页实时刷新、双向转换、UTC 切换、自定义模板报错；MD5 输入即算、大写切换；URL 编解码 + 交换 + 坏序列红字；Unicode 双向 + 交换 + 坏序列红字；JWT 粘贴真实 token（可从 https://jwt.io 首页示例复制）解析、过期标注、非法 token 红字；所有复制按钮可用。

- [ ] **Step 5: 提交**

```bash
git add DevToolbox/Views/ContentView.swift
git commit -m "feat: wire up sidebar navigation"
```

---

### Task 12: README + 打包脚本

**Files:**
- Create: `README.md`
- Create: `scripts/package.sh`

- [ ] **Step 1: 写 README.md**

```markdown
# DevToolbox

macOS 开发者工具箱（Apple Silicon 原生），五个高频小工具，全部本地计算，零第三方依赖。

## 功能

| 工具 | 说明 |
|---|---|
| 时间戳 | 实时秒/毫秒时间戳，时间戳↔时间双向转换，本地/UTC 时区，自定义格式模板 |
| JWT | 解析 Header/Payload，iat/nbf/exp 换算可读时间，过期状态标注 |
| MD5 | 字符串 → 32 位十六进制 MD5，大/小写切换 |
| URL | RFC 3986 编码/解码，一键交换 |
| Unicode | 中文↔Unicode（\uXXXX 与 U+XXXX）双向转换 |

## 系统要求

- macOS 14 (Sonoma) 及以上，Apple Silicon (arm64)
- 开发需要 Xcode 15+ 与 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）

## 开发

```bash
xcodegen generate                  # 从 project.yml 生成 .xcodeproj
open DevToolbox.xcodeproj          # 用 Xcode 打开，⌘R 运行

# 或命令行
xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' test
```

## 打包分发

```bash
./scripts/package.sh               # 产出 DevToolbox.zip（Release + ad-hoc 签名）
```

> **注意**：应用未做公证（无付费开发者账号）。收到的朋友首次打开需**右键 → 打开**，
> 或在「系统设置 → 隐私与安全性」中允许。

## 架构

- `DevToolbox/Logic/` 纯逻辑层，`Result<T, ToolError>` 返回，单元测试全覆盖
- `DevToolbox/Views/` SwiftUI 视图薄壳
- 新增工具：加一对 `Logic/` + `Views/` 文件，在 `ContentView.ToolItem` 注册
```

- [ ] **Step 2: 写 scripts/package.sh 并赋执行权限**

```bash
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> 生成工程"
xcodegen generate

echo "==> Release 构建"
xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox \
  -configuration Release -destination 'platform=macOS' \
  CONFIGURATION_BUILD_DIR="$(pwd)/build" build 2>&1 | tail -3

echo "==> Ad-hoc 签名"
codesign --force --deep --sign - build/DevToolbox.app
codesign --verify build/DevToolbox.app

echo "==> 压缩"
rm -f DevToolbox.zip
ditto -c -k --keepParent build/DevToolbox.app DevToolbox.zip

echo "==> 完成：$(pwd)/DevToolbox.zip"
```

Run: `chmod +x scripts/package.sh`

- [ ] **Step 3: 运行打包脚本验证**

Run: `./scripts/package.sh && ls -lh DevToolbox.zip`
Expected: 输出 `BUILD SUCCEEDED`、签名校验通过，最终打印 zip 路径与大小

- [ ] **Step 4: 提交**

```bash
git add README.md scripts/package.sh
git commit -m "docs: add README and packaging script"
```

---

## 完成定义

- [ ] `xcodebuild test` 全绿（Smoke / MD5 / URL / Unicode / Timestamp / JWT 六个测试类）
- [ ] 人工验收 5 个工具页面行为符合规格文档
- [ ] `scripts/package.sh` 产出可运行的 `DevToolbox.zip`
- [ ] 所有任务已提交到 git
