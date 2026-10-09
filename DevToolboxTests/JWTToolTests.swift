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

    func testParseHeaderAndPayload() throws {
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

    func testExpiredToken() throws {
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":1000000000}"# // 2001-09-09，早已过期
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertTrue(jwt.expired)
        // delta = 1759977600 - 1000000000 = 759977600 秒 = 8796 天
        XCTAssertEqual(jwt.expiryText, "已过期 8796 天")
    }

    func testNotExpiredToken() throws {
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":4102444800}"# // 2100-01-01
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertFalse(jwt.expired)
        // delta = 4102444800 - 1759977600 = 2342467200 秒 = 27111 天
        XCTAssertEqual(jwt.expiryText, "剩余 27111 天")
    }

    func testTimeAnnotations() throws {
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

    func testExpExactlyNowIsExpired() throws {
        // RFC 7519：now >= exp 即过期
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":1759977600}"#
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertTrue(jwt.expired)
        XCTAssertEqual(jwt.expiryText, "已过期 0 秒")
    }

    func testHugeExpDoesNotCrash() throws {
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

    func testStringExpIsCoerced() throws {
        // 部分发行方把 exp 写成字符串，不能误显示为"永不过期"
        let token = makeToken(
            header: #"{"alg":"HS256"}"#,
            payload: #"{"exp":"4102444800"}"#
        )
        let jwt = try JWTTool.parse(token, now: now, timeZone: utc).get()
        XCTAssertFalse(jwt.expired)
        XCTAssertEqual(jwt.expiryText, "剩余 27111 天")
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
