import Foundation
import Combine

public struct SamsungLocalConfig {
    public var ip: String
    public var port: Int
    public var token: String
    
    public init(ip: String? = nil, port: Int? = nil, token: String? = nil) {
        let env = ProcessInfo.processInfo.environment
        let defaults = UserDefaults.standard
        
        self.ip = ip
            ?? env["AC_IP"]
            ?? defaults.string(forKey: "aerobar_local_ip")
            ?? ""
            
        let portVal = port
            ?? env["AC_PORT"].flatMap(Int.init)
            ?? defaults.integer(forKey: "aerobar_local_port")
        self.port = portVal > 0 ? portVal : 8888
        
        self.token = token
            ?? env["AC_TOKEN"]
            ?? defaults.string(forKey: "aerobar_local_token")
            ?? ""
    }
    
    public var isValid: Bool {
        return !ip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public struct SamsungLocalStatus {
    public var power: Bool
    public var targetTemperature: Double?
    public var roomTemperature: Double?
    public var mode: String?
    public var rawResponse: [String: Any]?
    
    public init(power: Bool, targetTemperature: Double? = nil, roomTemperature: Double? = nil, mode: String? = nil, rawResponse: [String: Any]? = nil) {
        self.power = power
        self.targetTemperature = targetTemperature
        self.roomTemperature = roomTemperature
        self.mode = mode
        self.rawResponse = rawResponse
    }
}

public enum SamsungLocalError: LocalizedError {
    case missingIP
    case invalidURL(String)
    case unauthorized(String)
    case networkError(String)
    case invalidResponse(String)
    case deviceTimeout(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingIP:
            return "Local AC IP address is not configured. Please enter the IP in Settings."
        case .invalidURL(let u):
            return "Invalid AC URL: \(u)"
        case .unauthorized(let msg):
            return "Authentication failed (401/403): \(msg)"
        case .networkError(let msg):
            return "Network connection error: \(msg)"
        case .invalidResponse(let msg):
            return "Invalid response from AC: \(msg)"
        case .deviceTimeout(let msg):
            return "AC connection timed out: \(msg)"
        }
    }
}

/// Custom URLSessionDelegate that accepts self-signed certificates from Samsung Smart AC
public class InsecureSSLSessionDelegate: NSObject, URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            // Bypass TLS verification for self-signed certificates on local network
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

public class SamsungLocalACService {
    public static let shared = SamsungLocalACService()
    
    private let session: URLSession
    private let delegate = InsecureSSLSessionDelegate()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 10.0
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }
    
    // MARK: - Core API Methods
    
    /// GET https://${AC_IP}:${AC_PORT}/devices/0
    /// Retrieves live status, current room temp, target temp, and operational mode.
    public func getStatus(
        config: SamsungLocalConfig? = nil,
        completion: @escaping (Result<SamsungLocalStatus, Error>) -> Void
    ) {
        let activeConfig = config ?? SamsungLocalConfig()
        guard activeConfig.isValid else {
            completion(.failure(SamsungLocalError.missingIP))
            return
        }
        
        guard let url = URL(string: "https://\(activeConfig.ip):\(activeConfig.port)/devices/0") else {
            completion(.failure(SamsungLocalError.invalidURL("https://\(activeConfig.ip):\(activeConfig.port)/devices/0")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request, token: activeConfig.token)
        
        performRequestWithRetry(request: request, maxRetries: 2) { result in
            switch result {
            case .failure(let err):
                DispatchQueue.main.async { completion(.failure(err)) }
            case .success((let data, _)):
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    let rawStr = String(data: data, encoding: .utf8) ?? ""
                    DispatchQueue.main.async {
                        completion(.failure(SamsungLocalError.invalidResponse("Could not parse JSON: \(rawStr.prefix(120))")))
                    }
                    return
                }
                
                let status = Self.parseStatusResponse(json)
                DispatchQueue.main.async {
                    completion(.success(status))
                }
            }
        }
    }
    
    /// PUT https://${AC_IP}:${AC_PORT}/devices/0
    /// Payload: {"Device": {"Operation": {"power": "on" | "off"}}}
    public func setPower(
        _ on: Bool,
        config: SamsungLocalConfig? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "Device": [
                "Operation": [
                    "power": on ? "on" : "off"
                ]
            ]
        ]
        
        sendPut(payload: payload, config: config) { result in
            switch result {
            case .success:
                completion(.success("Power set to \(on ? "ON" : "OFF")"))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    /// PUT https://${AC_IP}:${AC_PORT}/devices/0
    /// Payload: {"Device": {"Operation": {"targetTemperature": tempC}}}
    public func setTargetTemperature(
        _ tempC: Double,
        config: SamsungLocalConfig? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let rounded = Int(round(tempC))
        let payload: [String: Any] = [
            "Device": [
                "Operation": [
                    "targetTemperature": rounded
                ]
            ]
        ]
        
        sendPut(payload: payload, config: config) { result in
            switch result {
            case .success:
                completion(.success("Target temperature set to \(rounded)°C"))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    /// PUT https://${AC_IP}:${AC_PORT}/devices/0
    /// Payload: {"Device": {"Operation": {"mode": mode}}}
    public func setMode(
        _ mode: String,
        config: SamsungLocalConfig? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let normalized = Self.normalizeSamsungMode(mode)
        let payload: [String: Any] = [
            "Device": [
                "Operation": [
                    "mode": normalized
                ]
            ]
        ]
        
        sendPut(payload: payload, config: config) { result in
            switch result {
            case .success:
                completion(.success("Mode set to \(normalized)"))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    /// Sync full state (power, temperature, mode) from AeroBar ACState
    public func syncState(
        state: ACState,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let config = SamsungLocalConfig(
            ip: state.samsungLocalIp,
            port: Int(state.samsungLocalPort),
            token: state.samsungLocalToken
        )
        
        guard config.isValid else {
            completion(.failure(SamsungLocalError.missingIP))
            return
        }
        
        if !state.isOn {
            // Powering off takes priority
            setPower(false, config: config) { result in
                DispatchQueue.main.async { completion(result) }
            }
            return
        }
        
        // Power ON and update settings
        setPower(true, config: config) { [weak self] pResult in
            guard let self = self else { return }
            switch pResult {
            case .failure(let err):
                DispatchQueue.main.async { completion(.failure(err)) }
            case .success:
                // Small 150ms delay between commands to avoid embedded device buffer stalls
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) {
                    self.setTargetTemperature(state.targetTemperature, config: config) { tResult in
                        switch tResult {
                        case .failure(let err):
                            DispatchQueue.main.async { completion(.failure(err)) }
                        case .success:
                            DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) {
                                let samsungMode = Self.mapACModeToSamsung(state.mode)
                                self.setMode(samsungMode, config: config) { mResult in
                                    DispatchQueue.main.async {
                                        switch mResult {
                                        case .success:
                                            completion(.success("Local Samsung AC updated: ON, \(Int(state.targetTemperature))°C, \(samsungMode)"))
                                        case .failure(let err):
                                            completion(.failure(err))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Trigger initial token request flow: tells AC to connect back to callbackPort (default 8889)
    public func requestDeviceToken(
        acIp: String,
        acPort: Int = 8888,
        callbackPort: Int = 8889,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "https://\(acIp):\(acPort)/devicetoken/request") else {
            completion(.failure(SamsungLocalError.invalidURL("https://\(acIp):\(acPort)/devicetoken/request")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("xxxxxxxxxxx", forHTTPHeaderField: "DeviceToken")
        request.httpBody = "{}".data(using: .utf8)
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                completion(.success("Token request submitted (HTTP \(status)). Check AC display or port \(callbackPort) listener."))
            }
        }.resume()
    }
    
    // MARK: - Private Helpers
    
    private func sendPut(
        payload: [String: Any],
        config: SamsungLocalConfig? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let activeConfig = config ?? SamsungLocalConfig()
        guard activeConfig.isValid else {
            completion(.failure(SamsungLocalError.missingIP))
            return
        }
        
        guard let url = URL(string: "https://\(activeConfig.ip):\(activeConfig.port)/devices/0") else {
            completion(.failure(SamsungLocalError.invalidURL("https://\(activeConfig.ip):\(activeConfig.port)/devices/0")))
            return
        }
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            completion(.failure(SamsungLocalError.invalidResponse("Failed to encode payload JSON")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        applyHeaders(to: &request, token: activeConfig.token)
        request.httpBody = httpBody
        
        performRequestWithRetry(request: request, maxRetries: 2) { result in
            switch result {
            case .failure(let err):
                DispatchQueue.main.async { completion(.failure(err)) }
            case .success((let data, _)):
                DispatchQueue.main.async { completion(.success(data)) }
            }
        }
    }
    
    private func applyHeaders(to request: inout URLRequest, token: String) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanToken.isEmpty {
            request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
            request.setValue(cleanToken, forHTTPHeaderField: "DeviceToken")
        }
    }
    
    private func performRequestWithRetry(
        request: URLRequest,
        maxRetries: Int,
        attempt: Int = 0,
        completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void
    ) {
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                let nsErr = error as NSError
                // Check if retryable network drop or timeout
                let isRetryable = nsErr.domain == NSURLErrorDomain &&
                    (nsErr.code == NSURLErrorTimedOut ||
                     nsErr.code == NSURLErrorNetworkConnectionLost ||
                     nsErr.code == NSURLErrorCannotConnectToHost)
                     
                if isRetryable && attempt < maxRetries {
                    let backoff = Double(attempt + 1) * 0.4
                    DispatchQueue.global().asyncAfter(deadline: .now() + backoff) {
                        self.performRequestWithRetry(
                            request: request,
                            maxRetries: maxRetries,
                            attempt: attempt + 1,
                            completion: completion
                        )
                    }
                    return
                }
                
                completion(.failure(SamsungLocalError.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(SamsungLocalError.invalidResponse("Invalid HTTP response")))
                return
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                completion(.failure(SamsungLocalError.unauthorized("Device rejected token (HTTP \(httpResponse.statusCode))")))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(SamsungLocalError.invalidResponse("Server responded with HTTP \(httpResponse.statusCode)")))
                return
            }
            
            completion(.success((data ?? Data(), httpResponse)))
        }.resume()
    }
    
    // MARK: - Parsing Logic
    
    public static func parseStatusResponse(_ json: [String: Any]) -> SamsungLocalStatus {
        // Samsung response structure can have Device object or Devices array
        var deviceObj: [String: Any] = [:]
        if let d = json["Device"] as? [String: Any] {
            deviceObj = d
        } else if let devices = json["Devices"] as? [[String: Any]], let first = devices.first {
            deviceObj = first
        } else {
            deviceObj = json
        }
        
        let op = (deviceObj["Operation"] as? [String: Any]) ?? deviceObj
        
        // 1. Power State
        var isOn = false
        if let powerStr = op["power"] as? String {
            isOn = (powerStr.lowercased() == "on")
        } else if let powerBool = op["power"] as? Bool {
            isOn = powerBool
        } else if let stateStr = op["state"] as? String {
            isOn = (stateStr.lowercased() == "on" || stateStr.lowercased() == "running")
        }
        
        // 2. Target Temperature
        var targetTemp: Double? = nil
        if let t = op["targetTemperature"] as? Double {
            targetTemp = t
        } else if let t = op["targetTemperature"] as? Int {
            targetTemp = Double(t)
        } else if let tStr = op["targetTemperature"] as? String, let t = Double(tStr) {
            targetTemp = t
        } else if let t = op["desired"] as? Double {
            targetTemp = t
        }
        
        // 3. Current Room Temperature
        var roomTemp: Double? = nil
        if let temps = (deviceObj["Temperatures"] as? [[String: Any]]) ?? (json["Temperatures"] as? [[String: Any]]) {
            for entry in temps {
                if let curr = entry["current"] as? Double {
                    roomTemp = curr
                    break
                } else if let curr = entry["current"] as? Int {
                    roomTemp = Double(curr)
                    break
                }
            }
        }
        if roomTemp == nil {
            if let curr = op["currentTemperature"] as? Double {
                roomTemp = curr
            } else if let curr = op["currentTemperature"] as? Int {
                roomTemp = Double(curr)
            }
        }
        
        // 4. Mode
        var modeStr: String? = nil
        if let m = op["mode"] as? String {
            modeStr = m
        } else if let m = op["operatingMode"] as? String {
            modeStr = m
        }
        
        return SamsungLocalStatus(
            power: isOn,
            targetTemperature: targetTemp,
            roomTemperature: roomTemp,
            mode: modeStr,
            rawResponse: json
        )
    }
    
    public static func normalizeSamsungMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "cool": return "Cool"
        case "wind", "fan": return "Wind"
        case "auto": return "Auto"
        case "dry": return "Dry"
        case "heat": return "Heat"
        default: return "Cool"
        }
    }
    
    public static func mapACModeToSamsung(_ mode: ACMode) -> String {
        switch mode {
        case .cool: return "Cool"
        case .fan: return "Wind"
        case .auto: return "Auto"
        case .dry: return "Dry"
        case .heat: return "Heat"
        }
    }
    
    public static func mapSamsungToACMode(_ samsungMode: String) -> ACMode {
        switch samsungMode.lowercased() {
        case "cool": return .cool
        case "wind", "fan": return .fan
        case "auto": return .auto
        case "dry": return .dry
        case "heat": return .heat
        default: return .cool
        }
    }
}
