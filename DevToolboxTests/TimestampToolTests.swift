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
