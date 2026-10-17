import Foundation

/// Since macOS Ventura, many rows in `message` have a NULL `text` column and
/// keep the body only in `attributedBody`: an NSAttributedString serialized
/// with the legacy `typedstream` (NSArchiver) format. Rather than unarchive it
/// (NSUnarchiver is deprecated and not available everywhere), pull the first
/// NSString payload out of the stream directly.
///
/// Layout after the "NSString" class name:
///   01 94 84 01 2B <length> <utf-8 bytes>
/// where <length> is one byte, or 0x81 + UInt16 LE, or 0x82 + UInt32 LE.
public enum AttributedBodyDecoder {
    public static func text(from blob: Data) -> String? {
        let bytes = [UInt8](blob)
        let marker = Array("NSString".utf8)
        guard let markerEnd = firstIndex(of: marker, in: bytes).map({ $0 + marker.count }) else { return nil }

        // The '+' (0x2B) type tag sits a few bytes after the class name.
        let searchEnd = min(bytes.count, markerEnd + 8)
        guard let plus = bytes[markerEnd..<searchEnd].firstIndex(of: 0x2B) else { return nil }

        var cursor = plus + 1
        guard cursor < bytes.count else { return nil }
        let length: Int
        switch bytes[cursor] {
        case 0x81:
            guard cursor + 2 < bytes.count else { return nil }
            length = Int(bytes[cursor + 1]) | Int(bytes[cursor + 2]) << 8
            cursor += 3
        case 0x82:
            guard cursor + 4 < bytes.count else { return nil }
            length = Int(bytes[cursor + 1]) | Int(bytes[cursor + 2]) << 8 | Int(bytes[cursor + 3]) << 16 | Int(bytes[cursor + 4]) << 24
            cursor += 5
        default:
            length = Int(bytes[cursor])
            cursor += 1
        }

        guard length > 0, cursor + length <= bytes.count else { return nil }
        return String(decoding: bytes[cursor..<cursor + length], as: UTF8.self)
    }

    private static func firstIndex(of needle: [UInt8], in haystack: [UInt8]) -> Int? {
        guard !needle.isEmpty, haystack.count >= needle.count else { return nil }
        for start in 0...(haystack.count - needle.count) where haystack[start] == needle[0] {
            if Array(haystack[start..<start + needle.count]) == needle {
                return start
            }
        }
        return nil
    }
}
