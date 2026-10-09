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
