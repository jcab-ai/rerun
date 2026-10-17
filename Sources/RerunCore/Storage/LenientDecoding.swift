import Foundation

extension KeyedDecodingContainer {
    /// Decodes a value that newer builds added, falling back when an older
    /// record doesn't have it.
    func decode<T: Decodable>(_ key: Key, default fallback: @autoclosure () -> T) throws -> T {
        try decodeIfPresent(T.self, forKey: key) ?? fallback()
    }
}
