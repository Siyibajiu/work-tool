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
