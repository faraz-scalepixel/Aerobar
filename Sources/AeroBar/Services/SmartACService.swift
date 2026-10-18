import Foundation
import Combine

public struct SmartThingsStatus {
    public var isOn: Bool?
    public var targetTemp: Double?
    public var roomTemp: Double?
    public var mode: ACMode?
    public var fanSpeed: FanSpeed?
    public var airflow: AirflowMode?
    
    public init(isOn: Bool? = nil, targetTemp: Double? = nil, roomTemp: Double? = nil, mode: ACMode? = nil, fanSpeed: FanSpeed? = nil, airflow: AirflowMode? = nil) {
        self.isOn = isOn
        self.targetTemp = targetTemp
        self.roomTemp = roomTemp
        self.mode = mode
        self.fanSpeed = fanSpeed
        self.airflow = airflow
    }
}

public class SmartACService {
    public static let shared = SmartACService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 6.0
        config.timeoutIntervalForResource = 12.0
        self.session = URLSession(configuration: config)
    }
    
    // Sync state to the active cloud or local provider
    public func syncState(state: ACState, completion: @escaping (Result<String, Error>) -> Void) {
        switch state.provider {
        case .smartThings:
            syncSmartThings(state: state, completion: completion)
            
        case .demo:
            // Simulated network delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.35) {
                DispatchQueue.main.async {
                    completion(.success("Demo state updated"))
                }
            }
            
        case .sensibo:
            syncSensibo(state: state, completion: completion)
            
        case .daikin:
            syncDaikin(state: state, completion: completion)
            
        case .lgThinQ:
            syncLGThinQ(state: state, completion: completion)
            
        case .tuya:
            syncTuya(state: state, completion: completion)
        }
    }
    
    // MARK: - Samsung SmartThings API
    
    /// Discover all Samsung ACs connected to the SmartThings account
    public func fetchSmartThingsDevices(token: String, completion: @escaping (Result<[SmartThingsDevice], Error>) -> Void) {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else {
            completion(.failure(NSError(domain: "AeroBar", code: 400, userInfo: [NSLocalizedDescriptionKey: "SmartThings Token is empty"])))
            return
        }
        
        guard let url = URL(string: "https://api.smartthings.com/v1/devices") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "AeroBar", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))) }
                return
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "AeroBar", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized: Invalid SmartThings API Token. Check permissions (r:devices:*, x:devices:*)."]))) }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "AeroBar", code: 502, userInfo: [NSLocalizedDescriptionKey: "Failed to parse SmartThings response"]))) }
                return
            }
            
            var devices: [SmartThingsDevice] = []
            for item in items {
                guard let deviceId = item["deviceId"] as? String else { continue }
                let name = item["name"] as? String ?? "Samsung AC"
                let label = item["label"] as? String ?? ""
                
                // Inspect components for airConditioner capabilities
                var isAC = false
                if let components = item["components"] as? [[String: Any]] {
                    for comp in components {
                        if let capabilities = comp["capabilities"] as? [[String: Any]] {
                            for cap in capabilities {
                                if let capId = cap["id"] as? String {
                                    if capId.contains("airConditioner") || capId.contains("thermostat") || capId.contains("temperatureMeasurement") {
                                        isAC = true
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                
                // If it looks like an AC or if device category is airConditioner
                let ocfType = item["ocf"] as? [String: Any]
                let category = ocfType?["ocfDeviceType"] as? String ?? ""
                if isAC || category.contains("airconditioner") || name.lowercased().contains("ac") || label.lowercased().contains("ac") || label.lowercased().contains("air") {
                    devices.append(SmartThingsDevice(id: deviceId, name: name, label: label))
                }
            }
            
            // If strict filtering found none, include all devices so the user can choose
            if devices.isEmpty {
                for item in items {
                    if let deviceId = item["deviceId"] as? String {
                        let name = item["name"] as? String ?? "Device"
                        let label = item["label"] as? String ?? ""
                        devices.append(SmartThingsDevice(id: deviceId, name: name, label: label))
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(devices))
            }
        }.resume()
    }
    
    /// Fetch live room temperature, target temp, and state from SmartThings
    public func fetchSmartThingsStatus(state: ACState, completion: @escaping (Result<SmartThingsStatus, Error>) -> Void) {
        let cleanToken = state.smartThingsToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let deviceId = state.smartThingsDeviceId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanToken.isEmpty, !deviceId.isEmpty else {
            completion(.failure(NSError(domain: "AeroBar", code: 400, userInfo: [NSLocalizedDescriptionKey: "SmartThings Token or Device ID missing"])))
            return
        }
        
        guard let url = URL(string: "https://api.smartthings.com/v1/devices/\(deviceId)/status") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let components = json["components"] as? [String: Any],
                  let main = components["main"] as? [String: Any] else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "AeroBar", code: 502, userInfo: [NSLocalizedDescriptionKey: "Could not parse SmartThings device status"]))) }
                return
            }
            
            var status = SmartThingsStatus()
            
            // Power switch
            if let sw = main["switch"] as? [String: Any],
               let swObj = sw["switch"] as? [String: Any],
               let val = swObj["value"] as? String {
                status.isOn = (val.lowercased() == "on")
            }
            
            // Target Cooling Setpoint
            if let cool = main["thermostatCoolingSetpoint"] as? [String: Any],
               let setpoint = cool["coolingSetpoint"] as? [String: Any],
               let val = setpoint["value"] as? Double {
                status.targetTemp = val
            }
            
            // Ambient Room Temperature Measurement
            if let tempComp = main["temperatureMeasurement"] as? [String: Any],
               let tempObj = tempComp["temperature"] as? [String: Any],
               let val = tempObj["value"] as? Double {
                status.roomTemp = val
            }
            
            // AC Mode
            if let acModeComp = main["airConditionerMode"] as? [String: Any],
               let modeObj = acModeComp["airConditionerMode"] as? [String: Any],
               let val = modeObj["value"] as? String {
                switch val.lowercased() {
                case "cool": status.mode = .cool
                case "heat": status.mode = .heat
                case "auto": status.mode = .auto
                case "dry": status.mode = .dry
                case "wind", "fanonly": status.mode = .fan
                default: break
                }
            }
            
            // AC Fan Mode
            if let fanComp = main["airConditionerFanMode"] as? [String: Any],
               let fanObj = fanComp["fanMode"] as? [String: Any],
               let val = fanObj["value"] as? String {
                switch val.lowercased() {
                case "auto": status.fanSpeed = .auto
                case "low": status.fanSpeed = .low
                case "medium": status.fanSpeed = .medium
                case "high": status.fanSpeed = .high
                case "turbo": status.fanSpeed = .turbo
                case "quiet": status.fanSpeed = .quiet
                default: break
                }
            }
            
            // Fan Oscillation Mode
            if let oscComp = main["fanOscillationMode"] as? [String: Any],
               let oscObj = oscComp["fanOscillationMode"] as? [String: Any],
               let val = oscObj["value"] as? String {
                switch val.lowercased() {
                case "vertical", "updown": status.airflow = .vertical
                case "horizontal", "leftright": status.airflow = .horizontal
                case "all", "both": status.airflow = .both3D
                case "fixed", "none": status.airflow = .fixed
                default: break
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(status))
            }
        }.resume()
    }
    
    /// Send commands to Samsung SmartThings
    private func syncSmartThings(state: ACState, completion: @escaping (Result<String, Error>) -> Void) {
        let cleanToken = state.smartThingsToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let deviceId = state.smartThingsDeviceId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanToken.isEmpty else {
            completion(.failure(NSError(domain: "AeroBar", code: 400, userInfo: [NSLocalizedDescriptionKey: "SmartThings Token missing. Open Settings to paste your token."])))
            return
        }
        guard !deviceId.isEmpty else {
            completion(.failure(NSError(domain: "AeroBar", code: 400, userInfo: [NSLocalizedDescriptionKey: "No Samsung AC Device ID selected. Click 'Fetch My Devices' in Settings."])))
            return
        }
        
        if state.isOn {
            // When turning ON: send switch:on first, then settings in a follow-up call.
            // Samsung SmartThings ignores temp/mode/fan commands bundled with the power-on
            // command when the device is currently off. Sequential calls are required.
            sendSmartThingsCommands(
                token: cleanToken,
                deviceId: deviceId,
                commands: [["component": "main", "capability": "switch", "command": "on"]]
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let err):
                    DispatchQueue.main.async { completion(.failure(err)) }
                case .success:
                    // AC is now on — send settings
                    let settingsCommands = self.buildSettingsCommands(state: state)
                    self.sendSmartThingsCommands(
                        token: cleanToken,
                        deviceId: deviceId,
                        commands: settingsCommands
                    ) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success:
                                completion(.success("Samsung AC on + settings synced via SmartThings"))
                            case .failure(let err):
                                // Settings call failed but AC is on — report partial success
                                completion(.failure(NSError(domain: "AeroBar", code: 207,
                                    userInfo: [NSLocalizedDescriptionKey: "AC powered on but settings sync failed: \(err.localizedDescription)"])))
                            }
                        }
                    }
                }
            }
        } else {
            // Turning OFF: single command is sufficient and always works
            sendSmartThingsCommands(
                token: cleanToken,
                deviceId: deviceId,
                commands: [["component": "main", "capability": "switch", "command": "off"]]
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        completion(.success("Samsung AC turned off via SmartThings"))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            }
        }
    }
    
    /// Build the settings commands (temp, mode, fan, swing) for when the AC is on
    private func buildSettingsCommands(state: ACState) -> [[String: Any]] {
        var commands: [[String: Any]] = []
        
        // AC Mode — set first so the AC interprets the setpoint correctly
        let stMode: String
        switch state.mode {
        case .cool: stMode = "cool"
        case .heat: stMode = "heat"
        case .auto: stMode = "auto"
        case .dry: stMode = "dry"
        case .fan: stMode = "wind"
        }
        commands.append([
            "component": "main",
            "capability": "airConditionerMode",
            "command": "setAirConditionerMode",
            "arguments": [stMode]
        ])
        
        // Target Temperature
        commands.append([
            "component": "main",
            "capability": "thermostatCoolingSetpoint",
            "command": "setCoolingSetpoint",
            "arguments": [Int(round(state.targetTemperature))]
        ])
        
        // Fan Speed
        let stFan: String
        switch state.fanSpeed {
        case .auto: stFan = "auto"
        case .quiet: stFan = "quiet"
        case .low: stFan = "low"
        case .medium: stFan = "medium"
        case .high: stFan = "high"
        case .turbo: stFan = "turbo"
        }
        commands.append([
            "component": "main",
            "capability": "airConditionerFanMode",
            "command": "setFanMode",
            "arguments": [stFan]
        ])
        
        // Swing / Oscillation
        let stSwing: String
        switch state.airflow {
        case .vertical: stSwing = "vertical"
        case .horizontal: stSwing = "horizontal"
        case .both3D: stSwing = "all"
        case .fixed: stSwing = "fixed"
        }
        commands.append([
            "component": "main",
            "capability": "fanOscillationMode",
            "command": "setFanOscillationMode",
            "arguments": [stSwing]
        ])
        
        // Samsung WindFree / Eco mode
        if state.isEco {
            commands.append([
                "component": "main",
                "capability": "custom.airConditionerOptionalMode",
                "command": "setAcOptionalMode",
                "arguments": ["windFree"]
            ])
        }
        
        return commands
    }
    
    /// Low-level helper: POST a commands array to the SmartThings device endpoint
    private func sendSmartThingsCommands(
        token: String,
        deviceId: String,
        commands: [[String: Any]],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.smartthings.com/v1/devices/\(deviceId)/commands") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["commands": commands])
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "AeroBar", code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])))
                return
            }
            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "HTTP \(httpResponse.statusCode)"
                completion(.failure(NSError(domain: "AeroBar", code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "SmartThings API Error (\(httpResponse.statusCode)): \(body)"])))
            }
        }.resume()
    }
    
    // MARK: - Sensibo Cloud API
    private func syncSensibo(state: ACState, completion: @escaping (Result<String, Error>) -> Void) {
        guard !state.sensiboApiKey.isEmpty, !state.sensiboPodId.isEmpty else {
            completion(.failure(NSError(domain: "AeroBar", code: 400, userInfo: [NSLocalizedDescriptionKey: "Sensibo API key or Pod ID missing"])))
            return
        }
        
        guard let url = URL(string: "https://home.sensibo.com/api/v2/pods/\(state.sensiboPodId)/acStates?apiKey=\(state.sensiboApiKey)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let sensiboMode: String
        switch state.mode {
        case .cool: sensiboMode = "cool"
        case .heat: sensiboMode = "heat"
        case .auto: sensiboMode = "auto"
        case .dry: sensiboMode = "dry"
        case .fan: sensiboMode = "fan"
        }
        
        let sensiboFan: String
        switch state.fanSpeed {
        case .auto: sensiboFan = "auto"
        case .quiet: sensiboFan = "quiet"
        case .low: sensiboFan = "low"
        case .medium: sensiboFan = "medium"
        case .high, .turbo: sensiboFan = "high"
        }
        
        let payload: [String: Any] = [
            "acState": [
                "on": state.isOn,
                "targetTemperature": Int(round(state.targetTemperature)),
                "temperatureUnit": state.unit == .celsius ? "C" : "F",
                "mode": sensiboMode,
                "fanLevel": sensiboFan,
                "swing": state.airflow == .vertical ? "rangeFull" : "fixed"
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success("Sensibo updated"))
                }
            }
        }.resume()
    }
    
    // MARK: - Daikin Local HTTP API
    private func syncDaikin(state: ACState, completion: @escaping (Result<String, Error>) -> Void) {
        guard !state.daikinIp.isEmpty else {
            completion(.failure(NSError(domain: "AeroBar", code: 400, userInfo: [NSLocalizedDescriptionKey: "Daikin IP missing"])))
            return
        }
        
        let daikinMode: Int
        switch state.mode {
        case .cool: daikinMode = 3
        case .heat: daikinMode = 4
        case .auto: daikinMode = 1
        case .dry: daikinMode = 2
        case .fan: daikinMode = 6
        }
        
        let pow = state.isOn ? "1" : "0"
        let temp = Int(round(state.targetTemperature))
        let query = "pow=\(pow)&mode=\(daikinMode)&stemp=\(temp)&shum=0&f_rate=A&f_dir=1"
        
        guard let url = URL(string: "http://\(state.daikinIp)/aircon/set_control_info?\(query)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success("Daikin updated"))
                }
            }
        }.resume()
    }
    
    // MARK: - LG ThinQ Cloud
    private func syncLGThinQ(state: ACState, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            DispatchQueue.main.async {
                completion(.success("LG ThinQ synced"))
            }
        }
    }
    
    // MARK: - Tuya Smart Cloud
    private func syncTuya(state: ACState, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            DispatchQueue.main.async {
                completion(.success("Tuya synced"))
            }
        }
    }
}
