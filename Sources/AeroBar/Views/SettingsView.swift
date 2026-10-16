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
                    if state.provider == .smartThings {
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
