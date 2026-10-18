import Foundation
import SwiftUI
import Combine

public enum ACMode: String, CaseIterable, Identifiable, Codable {
    case cool = "Cool"
    case heat = "Heat"
    case auto = "Auto"
    case dry = "Dry"
    case fan = "Fan"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .cool: return "snowflake"
        case .heat: return "flame.fill"
        case .auto: return "bolt.fill"
        case .dry: return "drop.fill"
        case .fan: return "wind"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .cool: return Color(red: 0.15, green: 0.75, blue: 1.0)
        case .heat: return Color(red: 1.0, green: 0.45, blue: 0.2)
        case .auto: return Color(red: 0.95, green: 0.8, blue: 0.2)
        case .dry: return Color(red: 0.75, green: 0.45, blue: 1.0)
        case .fan: return Color(white: 0.85)
        }
    }
    
    public var breezeColors: [Color] {
        switch self {
        case .cool:
            return [
                Color(red: 0.2, green: 0.8, blue: 1.0).opacity(0.8),
                Color(red: 0.1, green: 0.5, blue: 0.95).opacity(0.4),
                Color(red: 0.3, green: 0.9, blue: 1.0).opacity(0.15)
            ]
        case .heat:
            return [
                Color(red: 1.0, green: 0.5, blue: 0.2).opacity(0.8),
                Color(red: 0.95, green: 0.3, blue: 0.2).opacity(0.4),
                Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.15)
            ]
        case .auto:
            return [
                Color(red: 0.4, green: 0.85, blue: 0.95).opacity(0.8),
                Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.4),
                Color(white: 1.0).opacity(0.15)
            ]
        case .dry:
            return [
                Color(red: 0.75, green: 0.45, blue: 1.0).opacity(0.8),
                Color(red: 0.6, green: 0.3, blue: 0.9).opacity(0.4),
                Color(red: 0.85, green: 0.6, blue: 1.0).opacity(0.15)
            ]
        case .fan:
            return [
                Color(white: 0.9).opacity(0.7),
                Color(white: 0.75).opacity(0.35),
                Color(white: 0.6).opacity(0.12)
            ]
        }
    }
}

public enum FanSpeed: String, CaseIterable, Identifiable, Codable {
    case auto = "Auto"
    case quiet = "Quiet"
    case low = "Low"
    case medium = "Med"
    case high = "High"
    case turbo = "Turbo"
    
    public var id: String { rawValue }
    
    public var animationSpeedMultiplier: Double {
        switch self {
        case .quiet: return 0.5
        case .low: return 0.75
        case .medium: return 1.0
        case .high: return 1.4
        case .turbo: return 1.9
        case .auto: return 1.1
        }
    }
    
    public var rotationSpeed: Double {
        switch self {
        case .quiet: return 3.0
        case .low: return 2.0
        case .medium: return 1.2
        case .high: return 0.7
        case .turbo: return 0.35
        case .auto: return 1.1
        }
    }
}

public enum SleepDuration: String, CaseIterable, Identifiable, Codable {
    case off = "Off"
    case min30 = "30m"
    case hr1 = "1h"
    case hr2 = "2h"
    case hr4 = "4h"
    case hr8 = "8h"
    
    public var id: String { rawValue }
    
    public var minutes: Int {
        switch self {
        case .off: return 0
        case .min30: return 30
        case .hr1: return 60
        case .hr2: return 120
        case .hr4: return 240
        case .hr8: return 480
        }
    }
}

public enum AirflowMode: String, CaseIterable, Identifiable, Codable {
    case vertical = "Vertical"
    case horizontal = "Horizontal"
    case both3D = "3D Swing"
    case fixed = "Fixed"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .vertical: return "arrow.up.and.down.and.sparkles"
        case .horizontal: return "arrow.left.and.right"
        case .both3D: return "tornado"
        case .fixed: return "line.diagonal"
        }
    }
}

public enum TempUnit: String, CaseIterable, Identifiable, Codable {
    case celsius = "°C"
    case fahrenheit = "°F"
    
    public var id: String { rawValue }
}

public enum ConnectionStatus: String, Codable {
    case connected = "Connected"
    case syncing = "Syncing..."
    case disconnected = "Disconnected"
    
    public var iconName: String {
        switch self {
        case .connected: return "checkmark.shield.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .disconnected: return "exclamationmark.triangle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .connected: return Color(red: 0.2, green: 0.85, blue: 0.4)
        case .syncing: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case .disconnected: return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
    }
}

public enum ACProvider: String, CaseIterable, Identifiable, Codable {
    case samsungLocal = "Samsung Local Network"
    case smartThings = "Samsung SmartThings"
    case demo = "Demo Mode"
    case sensibo = "Sensibo"
    case daikin = "Daikin Smart"
    case lgThinQ = "LG ThinQ"
    case tuya = "Tuya / Smart Life"
    
    public var id: String { rawValue }
    
    public var subtitle: String {
        switch self {
        case .samsungLocal: return "Direct Samsung Smart AC control over local HTTPS (port 8888)"
        case .smartThings: return "Direct Samsung Smart AC control via SmartThings Personal Access Token"
        case .demo: return "Realistic in-memory AC simulation"
        case .sensibo: return "Cloud REST API via Sensibo Pod"
        case .daikin: return "Daikin SkyFi & BRP WiFi controller"
        case .lgThinQ: return "LG ThinQ OpenAPI smart appliances"
        case .tuya: return "Tuya Smart Cloud IoT platform"
        }
    }
}

public struct SmartThingsDevice: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let label: String
    
    public init(id: String, name: String, label: String) {
        self.id = id
        self.name = name
        self.label = label
    }
    
    public var displayName: String {
        return label.isEmpty ? name : label
    }
}

public class ACState: ObservableObject {
    @Published public var isOn: Bool = true {
        didSet { notifyBackend() }
    }
    
    @Published public var targetTemperature: Double = 21.0 {
        didSet { notifyBackend() }
    }
    
    @Published public var roomTemperature: Double = 23.0
    
    @Published public var mode: ACMode = .cool {
        didSet { notifyBackend() }
    }
    
    @Published public var fanSpeed: FanSpeed = .auto {
        didSet { notifyBackend() }
    }
    
    @Published public var sleepMode: SleepDuration = .off {
        didSet { notifyBackend() }
    }
    
    @Published public var airflow: AirflowMode = .vertical {
        didSet { notifyBackend() }
    }
    
    @Published public var isEco: Bool = false {
        didSet {
            if isEco && targetTemperature < 24.0 {
                targetTemperature = 24.0
            }
            notifyBackend()
        }
    }
    
    @Published public var unit: TempUnit = .celsius
    @Published public var connectionStatus: ConnectionStatus = .connected
    @Published public var deviceName: String = "Living Room AC"
    @Published public var soundEnabled: Bool = true
    @Published public var showingSettings: Bool = false
    @Published public var isDraggingSlider: Bool = false
    
    // Cloud & Local provider configuration
    @Published public var provider: ACProvider {
        didSet {
            UserDefaults.standard.set(provider.rawValue, forKey: "aerobar_provider")
            if provider == .samsungLocal {
                pollSamsungLocal()
                startLocalPollTimer()
            } else if provider == .smartThings {
                pollSmartThings()
                startSmartThingsPollTimer()
            } else {
                pollTimer?.cancel()
            }
        }
    }
    
    // Samsung Local Network (Port 8888 HTTPS)
    @Published public var samsungLocalIp: String {
        didSet {
            UserDefaults.standard.set(samsungLocalIp, forKey: "aerobar_local_ip")
        }
    }
    @Published public var samsungLocalPort: String {
        didSet {
            UserDefaults.standard.set(samsungLocalPort, forKey: "aerobar_local_port")
        }
    }
    @Published public var samsungLocalToken: String {
        didSet {
            UserDefaults.standard.set(samsungLocalToken, forKey: "aerobar_local_token")
        }
    }
    @Published public var samsungLocalUseHttps: Bool {
        didSet {
            UserDefaults.standard.set(samsungLocalUseHttps, forKey: "aerobar_local_https")
        }
    }
    @Published public var isScanningLocalNetwork: Bool = false
    @Published public var discoveredLocalIps: [String] = []
    @Published public var isListeningForToken: Bool = false
    @Published public var samsungLocalStatusMessage: String = ""
    
    // Samsung SmartThings
    @Published public var smartThingsToken: String {
        didSet {
            UserDefaults.standard.set(smartThingsToken, forKey: "aerobar_st_token")
        }
    }
    @Published public var smartThingsDeviceId: String {
        didSet {
            UserDefaults.standard.set(smartThingsDeviceId, forKey: "aerobar_st_device_id")
        }
    }
    @Published public var smartThingsDevicesList: [SmartThingsDevice] = []
    @Published public var isDiscoveringDevices: Bool = false
    @Published public var smartThingsStatusMessage: String = ""
    
    // Other Providers
    @Published public var sensiboApiKey: String = ""
    @Published public var sensiboPodId: String = ""
    @Published public var daikinIp: String = "192.168.1.150"
    @Published public var daikinKey: String = ""
    @Published public var lgToken: String = ""
    @Published public var tuyaClientId: String = ""
    @Published public var tuyaSecret: String = ""
    @Published public var tuyaDeviceId: String = ""
    
    private var ambientTimer: AnyCancellable?
    private var pollTimer: AnyCancellable?
    private var isSyncing: Bool = false
    private var hasPendingSync: Bool = false
    private var isUpdatingFromRemote: Bool = false
    private var debounceTimer: Timer?
    
    public static let shared = ACState()
    
    public init() {
        let env = ProcessInfo.processInfo.environment
        
        // Samsung Local Network Config
        let savedLocalIp = UserDefaults.standard.string(forKey: "aerobar_local_ip") ?? env["AC_IP"] ?? ""
        let savedLocalPort = UserDefaults.standard.string(forKey: "aerobar_local_port") ?? env["AC_PORT"] ?? "8888"
        let savedLocalToken = UserDefaults.standard.string(forKey: "aerobar_local_token") ?? env["AC_TOKEN"] ?? ""
        let savedLocalHttps = UserDefaults.standard.object(forKey: "aerobar_local_https") as? Bool ?? true
        self.samsungLocalIp = savedLocalIp
        self.samsungLocalPort = savedLocalPort
        self.samsungLocalToken = savedLocalToken
        self.samsungLocalUseHttps = savedLocalHttps
        
        // SmartThings Config
        let savedToken = UserDefaults.standard.string(forKey: "aerobar_st_token") ?? ""
        let savedDevice = UserDefaults.standard.string(forKey: "aerobar_st_device_id") ?? ""
        self.smartThingsToken = savedToken
        self.smartThingsDeviceId = savedDevice
        
        let savedProviderRaw = UserDefaults.standard.string(forKey: "aerobar_provider")
        if let raw = savedProviderRaw, let p = ACProvider(rawValue: raw) {
            self.provider = p
        } else if !savedLocalIp.isEmpty {
            self.provider = .samsungLocal
        } else if !savedToken.isEmpty {
            self.provider = .smartThings
        } else {
            self.provider = .samsungLocal // Prioritize Samsung Local if available
        }
        
        startAmbientSimulation()
        
        if self.provider == .samsungLocal && !savedLocalIp.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.pollSamsungLocal()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startLocalPollTimer()
            }
        } else if self.provider == .smartThings && !savedToken.isEmpty && !savedDevice.isEmpty {
            // Initial poll after 1s to hydrate state from real device
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.pollSmartThings()
            }
            // Periodic poll every 30s to stay in sync with Alexa/manual changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startSmartThingsPollTimer()
            }
        }
    }
    
    /// Start a 30-second polling timer for Samsung Local Network
    public func startLocalPollTimer() {
        pollTimer?.cancel()
        guard provider == .samsungLocal, !samsungLocalIp.isEmpty else { return }
        pollTimer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pollSamsungLocal()
            }
    }
    
    /// Start a 30-second polling timer to keep UI in sync with real AC state
    public func startSmartThingsPollTimer() {
        pollTimer?.cancel()
        guard provider == .smartThings, !smartThingsToken.isEmpty, !smartThingsDeviceId.isEmpty else { return }
        pollTimer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pollSmartThings()
            }
    }
    
    public var minTemperature: Double {
        unit == .celsius ? 16.0 : 60.0
    }
    
    public var maxTemperature: Double {
        unit == .celsius ? 32.0 : 90.0
    }
    
    public var formattedTargetTemp: String {
        return "\(Int(round(targetTemperature)))"
    }
    
    public var formattedRoomTemp: String {
        return String(format: "%.0f", roomTemperature)
    }
    
    public func stepTemperature(by delta: Double) {
        let newTemp = (targetTemperature + delta).clamped(to: minTemperature...maxTemperature)
        if newTemp != targetTemperature {
            targetTemperature = newTemp
            SoundManager.shared.playBeep(isDouble: false)
        }
    }
    
    public func togglePower() {
        isOn.toggle()
        SoundManager.shared.playBeep(isDouble: true)
    }
    
    public func toggleEco() {
        isEco.toggle()
        SoundManager.shared.playBeep(isDouble: false)
    }
    
    public func notifyBackend() {
        guard !isUpdatingFromRemote else { return }
        
        // Debounce rapid successive changes (e.g. slider drag) by 300ms
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.performSync()
        }
    }
    
    private func performSync() {
        if isSyncing {
            // A sync is already in-flight — mark pending so we re-sync when it finishes
            hasPendingSync = true
            return
        }
        
        isSyncing = true
        hasPendingSync = false
        connectionStatus = .syncing
        
        SmartACService.shared.syncState(state: self) { [weak self] result in
            guard let self = self else { return }
            self.isSyncing = false
            switch result {
            case .success(let msg):
                self.connectionStatus = .connected
                if self.provider == .samsungLocal {
                    self.samsungLocalStatusMessage = msg
                } else {
                    self.smartThingsStatusMessage = msg
                }
            case .failure(let error):
                self.connectionStatus = .disconnected
                if self.provider == .samsungLocal {
                    self.samsungLocalStatusMessage = error.localizedDescription
                } else {
                    self.smartThingsStatusMessage = error.localizedDescription
                }
            }
            // If state changed while we were syncing, send the latest state now
            if self.hasPendingSync {
                self.performSync()
            }
        }
    }
    
    public func pollSamsungLocal() {
        guard provider == .samsungLocal, !samsungLocalIp.isEmpty else { return }
        
        let config = SamsungLocalConfig(
            ip: samsungLocalIp,
            port: Int(samsungLocalPort),
            token: samsungLocalToken,
            useHttps: samsungLocalUseHttps
        )
        
        SamsungLocalACService.shared.getStatus(config: config) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let status):
                self.isUpdatingFromRemote = true
                self.connectionStatus = .connected
                self.isOn = status.power
                if let target = status.targetTemperature {
                    self.targetTemperature = target
                }
                if let room = status.roomTemperature {
                    self.roomTemperature = room
                }
                if let m = status.mode {
                    self.mode = SamsungLocalACService.mapSamsungToACMode(m)
                }
                self.isUpdatingFromRemote = false
                self.samsungLocalStatusMessage = "Connected to \(self.samsungLocalIp):\(self.samsungLocalPort) • \(status.power ? "ON" : "OFF") • \(Int(self.targetTemperature))°C"
            case .failure(let err):
                self.connectionStatus = .disconnected
                self.samsungLocalStatusMessage = "Status Error: \(err.localizedDescription)"
            }
        }
    }
    
    public func scanLocalNetwork() {
        isScanningLocalNetwork = true
        samsungLocalStatusMessage = "Scanning local network for Samsung ACs..."
        
        let portNum = UInt16(samsungLocalPort) ?? 8888
        LocalNetworkScanner.shared.scan(port: portNum, progress: { [weak self] progressMsg in
            self?.samsungLocalStatusMessage = progressMsg
        }) { [weak self] discovered in
            guard let self = self else { return }
            self.isScanningLocalNetwork = false
            self.discoveredLocalIps = discovered
            if let first = discovered.first {
                if self.samsungLocalIp.isEmpty {
                    self.samsungLocalIp = first
                }
                self.samsungLocalStatusMessage = "Found \(discovered.count) device(s). Selected \(first)."
                self.pollSamsungLocal()
                self.startLocalPollTimer()
            } else {
                self.samsungLocalStatusMessage = "No devices responded on port \(portNum). You can enter the IP manually."
            }
        }
    }
    
    public func startTokenCaptureServer() {
        isListeningForToken = true
        samsungLocalStatusMessage = "Listening on port 8889 for AC token..."
        
        TokenInterceptorServer.shared.start(port: 8889, onToken: { [weak self] token in
            guard let self = self else { return }
            self.isListeningForToken = false
            self.samsungLocalToken = token
            self.samsungLocalStatusMessage = "Token captured! Testing connection..."
            self.pollSamsungLocal()
        }, onStatus: { [weak self] msg in
            self?.samsungLocalStatusMessage = msg
        })
    }
    
    public func stopTokenCaptureServer() {
        isListeningForToken = false
        TokenInterceptorServer.shared.stop()
    }
    
    public func pollSmartThings() {
        guard provider == .smartThings, !smartThingsToken.isEmpty, !smartThingsDeviceId.isEmpty else { return }
        
        SmartACService.shared.fetchSmartThingsStatus(state: self) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let status):
                self.isUpdatingFromRemote = true
                self.connectionStatus = .connected
                if let on = status.isOn { self.isOn = on }
                if let target = status.targetTemp { self.targetTemperature = target }
                if let room = status.roomTemp { self.roomTemperature = room }
                if let mode = status.mode { self.mode = mode }
                if let fan = status.fanSpeed { self.fanSpeed = fan }
                if let swing = status.airflow { self.airflow = swing }
                self.isUpdatingFromRemote = false
            case .failure(let err):
                self.connectionStatus = .disconnected
                self.smartThingsStatusMessage = "Sync error: \(err.localizedDescription)"
            }
        }
    }
    
    public func discoverDevices() {
        guard !smartThingsToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            smartThingsStatusMessage = "Please enter your SmartThings Token first."
            return
        }
        
        isDiscoveringDevices = true
        smartThingsStatusMessage = "Connecting to SmartThings API..."
        
        SmartACService.shared.fetchSmartThingsDevices(token: smartThingsToken) { [weak self] result in
            guard let self = self else { return }
            self.isDiscoveringDevices = false
            switch result {
            case .success(let devices):
                self.smartThingsDevicesList = devices
                if let first = devices.first {
                    if self.smartThingsDeviceId.isEmpty {
                        self.smartThingsDeviceId = first.id
                        self.deviceName = first.displayName
                    }
                    self.smartThingsStatusMessage = "Found \(devices.count) device(s). Connected to \(first.displayName)."
                    self.pollSmartThings()
                    self.startSmartThingsPollTimer()
                } else {
                    self.smartThingsStatusMessage = "No air conditioners found in this SmartThings account."
                }
            case .failure(let err):
                self.smartThingsStatusMessage = "API Error: \(err.localizedDescription)"
            }
        }
    }
    
    private func startAmbientSimulation() {
        // Subtle natural ambient room temperature drift when AC is running vs off
        ambientTimer = Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Only run simulation in demo mode — real devices use pollSmartThings
                guard self.provider == .demo else { return }
                if self.isOn {
                    // Drift slowly towards target
                    let diff = self.targetTemperature - self.roomTemperature
                    if abs(diff) > 0.3 {
                        self.roomTemperature += diff > 0 ? 0.2 : -0.2
                    }
                } else {
                    // Slowly drift toward ambient outside 25°C
                    if self.roomTemperature < 25.0 {
                        self.roomTemperature += 0.1
                    }
                }
            }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
