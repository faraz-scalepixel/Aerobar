import SwiftUI

public struct SettingsView: View {
    @ObservedObject var state: ACState
    @Environment(\.dismiss) private var dismiss
    
    public init(state: ACState) {
        self.state = state
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AeroBar Settings")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(white: 0.45))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Integration Provider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SMART AC INTEGRATION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(white: 0.45))
                        
                        Picker("", selection: $state.provider) {
                            ForEach(ACProvider.allCases) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        
                        Text(state.provider.subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.55))
                    }
                    
                    // Provider-specific config fields
                    if state.provider == .samsungLocal {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "wifi.router.fill")
                                    .foregroundColor(Color(red: 0.15, green: 0.75, blue: 1.0))
                                Text("Samsung Local Network (LAN)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("HTTPS Port 8888")
                                    .font(.system(size: 9, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.blue.opacity(0.2)))
                                    .foregroundColor(Color(red: 0.3, green: 0.75, blue: 1.0))
                            }
                            
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AC IP Address")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(white: 0.6))
                                    TextField("e.g. 192.168.1.100", text: $state.samsungLocalIp)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Port")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(white: 0.6))
                                    TextField("8888", text: $state.samsungLocalPort)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 50)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Protocol")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(white: 0.6))
                                    Picker("", selection: $state.samsungLocalUseHttps) {
                                        Text("HTTPS").tag(true)
                                        Text("HTTP").tag(false)
                                    }
                                    .pickerStyle(PopUpButtonPickerStyle())
                                    .frame(width: 80)
                                }
                            }
                            
                            // Network Scan & Discover button
                            HStack {
                                Button(action: {
                                    state.scanLocalNetwork()
                                }) {
                                    HStack(spacing: 4) {
                                        if state.isScanningLocalNetwork {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "magnifyingglass")
                                        }
                                        Text(state.isScanningLocalNetwork ? "Scanning..." : "Scan Network for AC")
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.22)))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(state.isScanningLocalNetwork)
                                
                                Spacer()
                                
                                Button(action: {
                                    state.pollSamsungLocal()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "bolt.fill")
                                        Text("Test Connection")
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.1, green: 0.5, blue: 0.95)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Discovered devices chips
                            if !state.discoveredLocalIps.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Found on Local Network:")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(white: 0.6))
                                    
                                    HStack(spacing: 6) {
                                        ForEach(state.discoveredLocalIps, id: \.self) { foundIp in
                                            Button(action: {
                                                state.samsungLocalIp = foundIp
                                                state.pollSamsungLocal()
                                            }) {
                                                HStack(spacing: 3) {
                                                    Image(systemName: foundIp == state.samsungLocalIp ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 9))
                                                    Text(foundIp)
                                                        .font(.system(size: 10, weight: .medium))
                                                }
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(RoundedRectangle(cornerRadius: 5).fill(foundIp == state.samsungLocalIp ? Color.blue.opacity(0.3) : Color(white: 0.2)))
                                                .foregroundColor(foundIp == state.samsungLocalIp ? Color(red: 0.4, green: 0.8, blue: 1.0) : .white)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Device Authorization Token (Bearer)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(white: 0.6))
                                    Spacer()
                                    Button(action: {
                                        if state.isListeningForToken {
                                            state.stopTokenCaptureServer()
                                        } else {
                                            state.startTokenCaptureServer()
                                        }
                                    }) {
                                        HStack(spacing: 3) {
                                            Image(systemName: state.isListeningForToken ? "stop.fill" : "ear.badge.waveform")
                                            Text(state.isListeningForToken ? "Stop (Port 8889)" : "Capture Token (8889)")
                                        }
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(state.isListeningForToken ? .orange : Color(red: 0.3, green: 0.75, blue: 1.0))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                SecureField("Paste Token or click Capture Token", text: $state.samsungLocalToken)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            if !state.samsungLocalStatusMessage.isEmpty {
                                Text(state.samsungLocalStatusMessage)
                                    .font(.system(size: 10))
                                    .foregroundColor(
                                        state.samsungLocalStatusMessage.contains("Error") ? Color.red :
                                        (state.samsungLocalStatusMessage.contains("Connected") || state.samsungLocalStatusMessage.contains("captured") || state.samsungLocalStatusMessage.contains("Found")) ? Color(red: 0.3, green: 0.9, blue: 0.5) :
                                        Color(red: 0.95, green: 0.8, blue: 0.2)
                                    )
                                    .lineLimit(3)
                            }
                            
                            Text("💡 Tip: Local Samsung AC API uses port 8888. If you get a TLS error, verify the IP belongs to your AC (and not an Echo speaker or router) or try toggling HTTP.")
                                .font(.system(size: 9))
                                .foregroundColor(Color(white: 0.45))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.12)))
                    } else if state.provider == .smartThings {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(Color(red: 0.15, green: 0.7, blue: 1.0))
                                Text("Samsung SmartThings API")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            Text("Personal Access Token")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            
                            SecureField("Paste your SmartThings API Token", text: $state.smartThingsToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                Button(action: {
                                    if let url = URL(string: "https://account.smartthings.com/tokens") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.right.square")
                                        Text("Get Token from Samsung")
                                    }
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(red: 0.3, green: 0.7, blue: 1.0))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                                
                                Button(action: {
                                    state.discoverDevices()
                                }) {
                                    HStack(spacing: 4) {
                                        if state.isDiscoveringDevices {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                        }
                                        Text("Fetch My Devices")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.1, green: 0.5, blue: 0.95)))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(state.isDiscoveringDevices)
                            }
                            
                            if !state.smartThingsDevicesList.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Select Your Samsung AC:")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(white: 0.6))
                                    
                                    Picker("", selection: $state.smartThingsDeviceId) {
                                        ForEach(state.smartThingsDevicesList) { dev in
                                            Text(dev.displayName).tag(dev.id)
                                        }
                                    }
                                    .pickerStyle(PopUpButtonPickerStyle())
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Device ID (or click Fetch My Devices above)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(white: 0.6))
                                    
                                    TextField("Device UUID", text: $state.smartThingsDeviceId)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            
                            if !state.smartThingsStatusMessage.isEmpty {
                                Text(state.smartThingsStatusMessage)
                                    .font(.system(size: 10))
                                    .foregroundColor(state.smartThingsStatusMessage.contains("Error") ? Color.red : Color(red: 0.3, green: 0.9, blue: 0.5))
                                    .lineLimit(2)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.12)))
                    } else if state.provider == .sensibo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sensibo API Key")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            SecureField("Enter Sensibo API Key", text: $state.sensiboApiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Sensibo Pod ID")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            TextField("e.g. abc12345", text: $state.sensiboPodId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.1)))
                    } else if state.provider == .daikin {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daikin WiFi Unit IP Address")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            TextField("192.168.1.150", text: $state.daikinIp)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.1)))
                    } else if state.provider == .tuya {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tuya Client ID")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            TextField("Access ID", text: $state.tuyaClientId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Tuya Secret")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            SecureField("Access Secret", text: $state.tuyaSecret)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Tuya Device ID")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            TextField("Device ID", text: $state.tuyaDeviceId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.1)))
                    } else if state.provider == .lgThinQ {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LG ThinQ API Token")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.6))
                            SecureField("Enter Personal Access Token", text: $state.lgToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.1)))
                    }
                    
                    // Section 2: Preferences
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PREFERENCES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(white: 0.45))
                        
                        HStack {
                            Text("Temperature Unit")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $state.unit) {
                                ForEach(TempUnit.allCases) { u in
                                    Text(u.rawValue).tag(u)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 100)
                        }
                        
                        Toggle(isOn: $state.soundEnabled) {
                            Text("Authentic Remote Beep Sound")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle())
                    }
                    
                    // Section 3: Device Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DEVICE NAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(white: 0.45))
                        
                        TextField("Living Room AC", text: $state.deviceName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Quit application
                    HStack {
                        Spacer()
                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text("Quit AeroBar")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.red.opacity(0.85))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .frame(width: 320, height: 420)
        .background(Color(white: 0.08))
    }
}
