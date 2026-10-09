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
