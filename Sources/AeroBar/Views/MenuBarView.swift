import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var state: ACState
    
    public init(state: ACState = .shared) {
        self.state = state
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // MARK: - Header
            HStack(alignment: .center) {
                // Room Sensor Temp
                HStack(spacing: 6) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(white: 0.75))
                    
                    Text("Room \(state.formattedRoomTemp)\(state.unit.rawValue)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Power Toggle Button
                Button(action: {
                    state.togglePower()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.14))
                        
                        // Glowing Accent Ring when Active
                        Circle()
                            .stroke(
                                state.isOn ?
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.75, blue: 0.35),
                                        Color(red: 0.95, green: 0.55, blue: 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .shadow(color: state.isOn ? Color(red: 0.95, green: 0.65, blue: 0.25).opacity(0.5) : Color.clear, radius: 4)
                        
                        Image(systemName: "power")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(state.isOn ? Color(red: 0.95, green: 0.75, blue: 0.35) : Color(white: 0.45))
                    }
                    .frame(width: 38, height: 38)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            // MARK: - Animated 3D AC Unit Visualizer
            ACUnitView(state: state)
                .padding(.top, -6)
            
            // MARK: - Target Temperature & Eco Mode Pill
            HStack(alignment: .center) {
                // Large Target Temperature
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(state.formattedTargetTemp)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(state.isOn ? .white : Color(white: 0.45))
                    
                    Text(state.unit.rawValue)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(state.isOn ? Color(white: 0.8) : Color(white: 0.35))
                }
                
                Spacer()
                
                // Eco Mode Toggle Pill
                Button(action: {
                    state.toggleEco()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(state.isEco ? Color(red: 0.2, green: 0.9, blue: 0.5) : Color(white: 0.5))
                        
                        Text("Eco Mode")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(state.isOn ? .white : Color(white: 0.45))
                        
                        // Mini Custom Switch
                        ZStack(alignment: state.isEco ? .trailing : .leading) {
                            Capsule()
                                .fill(state.isEco ? Color(red: 0.2, green: 0.85, blue: 0.45) : Color(white: 0.25))
                                .frame(width: 32, height: 18)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .padding(2)
                                .shadow(radius: 1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(white: 0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(state.isEco ? Color(red: 0.2, green: 0.85, blue: 0.45).opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!state.isOn)
            }
            .padding(.horizontal, 4)
            
            // MARK: - Temperature Slider & Steppers
            TemperatureSlider(state: state)
                .padding(.horizontal, 2)
            
            // MARK: - 4 Action Mode Cards
            FeatureCardsRow(state: state)
                .padding(.top, 2)
            
            // MARK: - Bottom Tray (Status & Settings)
            HStack(alignment: .center) {
                // Connection Status
                HStack(spacing: 6) {
                    Image(systemName: state.connectionStatus.iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(state.connectionStatus.color)
                    
                    Text(state.connectionStatus == .connected ? "Connected" : state.connectionStatus.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.7))
                }
                
                Spacer()
                
                // Settings Button
                Button(action: {
                    state.showingSettings = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                        .padding(6)
                        .background(Circle().fill(Color(white: 0.12)))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $state.showingSettings) {
                    SettingsView(state: state)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
        .padding(16)
        .frame(width: 330)
        .background(
            ZStack {
                Color(white: 0.07).opacity(0.96)
                
                // Top subtle pointer notch / glow
                VStack {
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    Spacer()
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }
}
