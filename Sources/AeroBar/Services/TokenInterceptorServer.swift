import Foundation
import Network

public class TokenInterceptorServer {
    public static let shared = TokenInterceptorServer()
    
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.aerobar.tokeninterceptor", qos: .userInitiated)
    
    public private(set) var isRunning: Bool = false
    public var onTokenCaptured: ((String) -> Void)?
    public var onStatusChanged: ((String) -> Void)?
    
    private init() {}
    
    /// Start listening on port 8889 (or custom port) for incoming token handshake
    public func start(
        port: UInt16 = 8889,
        onToken: @escaping (String) -> Void,
        onStatus: ((String) -> Void)? = nil
    ) {
        stop()
        
        self.onTokenCaptured = onToken
        self.onStatusChanged = onStatus
        
        do {
            let nwPort = NWEndpoint.Port(rawValue: port) ?? NWEndpoint.Port(integerLiteral: 8889)
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: params, on: nwPort)
            
            listener?.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    self.isRunning = true
                    let msg = "Token Interceptor active on port \(port). Ready to capture AC handshake."
                    DispatchQueue.main.async {
                        self.onStatusChanged?(msg)
                    }
                case .failed(let err):
                    self.isRunning = false
                    let msg = "Token Interceptor failed on port \(port): \(err.localizedDescription)"
                    DispatchQueue.main.async {
                        self.onStatusChanged?(msg)
                    }
                case .cancelled:
                    self.isRunning = false
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            
            listener?.start(queue: queue)
        } catch {
            let msg = "Could not start port \(port) listener: \(error.localizedDescription)"
            DispatchQueue.main.async {
                onStatus?(msg)
            }
        }
    }
    
    /// Stop the server listener
    public func stop() {
        if let l = listener {
            l.cancel()
            listener = nil
        }
        isRunning = false
        DispatchQueue.main.async { [weak self] in
            self?.onStatusChanged?("Token listener stopped.")
        }
    }
    
    // MARK: - Connection Handling
    
    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, let requestString = String(data: data, encoding: .utf8) {
                if let extractedToken = self.extractToken(from: requestString) {
                    // Send HTTP 200 OK Response back to AC
                    let responseBody = "{\"status\":\"ok\",\"message\":\"token_received\"}\n"
                    let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(responseBody.utf8.count)\r\nConnection: close\r\n\r\n\(responseBody)"
                    
                    if let respData = httpResponse.data(using: .utf8) {
                        connection.send(content: respData, completion: .contentProcessed({ _ in
                            connection.cancel()
                        }))
                    } else {
                        connection.cancel()
                    }
                    
                    DispatchQueue.main.async {
                        self.onTokenCaptured?(extractedToken)
                        self.onStatusChanged?("Successfully captured AC Token: \(extractedToken.prefix(8))...")
                    }
                    return
                }
            }
            
            // If no token recognized yet, acknowledge HTTP request anyway
            let ack = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            connection.send(content: ack.data(using: .utf8), completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }
    
    /// Extracts token from HTTP request header, JSON body, or URL params
    public func extractToken(from request: String) -> String? {
        let lines = request.components(separatedBy: "\r\n")
        
        // 1. Check HTTP Headers: DeviceToken or Authorization
        for line in lines {
            let lower = line.lowercased()
            if lower.hasPrefix("devicetoken:") {
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let token = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !token.isEmpty && token != "xxxxxxxxxxx" {
                        return token
                    }
                }
            } else if lower.hasPrefix("authorization:") {
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let val = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if val.lowercased().hasPrefix("bearer ") {
                        let token = String(val.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !token.isEmpty {
                            return token
                        }
                    }
                }
            }
        }
        
        // 2. Check JSON Body for "token" or "DeviceToken"
        if let bodyStart = request.range(of: "\r\n\r\n")?.upperBound {
            let body = String(request[bodyStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let bodyData = body.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                if let t = json["token"] as? String, !t.isEmpty {
                    return t
                }
                if let t = json["DeviceToken"] as? String, !t.isEmpty && t != "xxxxxxxxxxx" {
                    return t
                }
                if let t = json["deviceToken"] as? String, !t.isEmpty {
                    return t
                }
            }
        }
        
        // 3. Check URL query parameters (e.g. GET /?token=...)
        if let firstLine = lines.first, firstLine.contains("token=") {
            let pattern = "token=([a-zA-Z0-9_-]+)"
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: firstLine, range: NSRange(firstLine.startIndex..., in: firstLine)),
               let range = Range(match.range(at: 1), in: firstLine) {
                return String(firstLine[range])
            }
        }
        
        return nil
    }
}
