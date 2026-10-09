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
        XCTAssertEqual(MD5Tool.hex("line1\nline2"), "ee5a58024a155466b43bc559d953e018")
    }

    func testChineseInput() {
        XCTAssertEqual(MD5Tool.hex("中文"), "a7bac2239fcdcb3a067903d8077c4a07")
    }
}
