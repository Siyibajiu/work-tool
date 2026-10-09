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
        XCTAssertEqual(UnicodeTool.toChinese("U+4F60 U+597D"), .success("你好"))
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

    // MARK: - 往返

    func testRoundTrip() {
        let original = "你好 world 😀"
        XCTAssertEqual(UnicodeTool.toChinese(UnicodeTool.toUnicode(original)), .success(original))
    }
}
