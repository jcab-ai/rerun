import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The only way rerun talks to the network. Swappable for tests.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let http = response as? HTTPURLResponse {
                    continuation.resume(returning: (data ?? Data(), http))
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }.resume()
        }
    }
}

enum JSONRequest {
    static func make(url: URL, headers: [String: String], body: [String: Any], timeout: TimeInterval = 300) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        return request
    }

    static func send(_ request: URLRequest, via transport: HTTPTransport) async throws -> [String: Any] {
        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            throw LLMError.http(status: response.statusCode, body: String(decoding: data, as: UTF8.self))
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.malformedResponse("not a JSON object")
        }
        return object
    }
}
