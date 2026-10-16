import SwiftUI

public struct ACUnitView: View {
    @ObservedObject var state: ACState
    
    public init(state: ACState) {
        self.state = state
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !state.isOn)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let speedMultiplier = state.fanSpeed.animationSpeedMultiplier
            let phase = date * 2.8 * speedMultiplier
            
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    // Airflow Breeze Streams (behind or emerging from vent)
                    if state.isOn {
                        AirflowBreezeView(
                            phase: phase,
                            mode: state.mode,
                            speed: state.fanSpeed,
                            airflow: state.airflow,
                            isEco: state.isEco
                        )
                        .frame(width: 280, height: 110)
                        .offset(y: 52)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // 3D Split AC Unit Model
                    ACChassisView(isOn: state.isOn, targetTemp: state.formattedTargetTemp)
                        .frame(width: 210, height: 65)
                        .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 10)
                    
                    // Motorized Vent Louver Flap
                    ACLouverFlap(isOpen: state.isOn, airflow: state.airflow)
                        .frame(width: 184, height: 10)
                        .offset(y: 50)
                }
                .frame(height: 165)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: state.isOn)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: state.airflow)
            .animation(.easeInOut(duration: 0.3), value: state.mode)
        }
    }
}

// MARK: - AC Main Chassis
struct ACChassisView: View {
    let isOn: Bool
    let targetTemp: String
    
    var body: some View {
        ZStack {
            // Main Body Base
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.96),
                            Color(white: 0.88),
                            Color(white: 0.82)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Top bevel highlight
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
            
            // Bottom exhaust vent recession
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.15))
                    .frame(height: 12)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .overlay(
                        // Internal vent blades
                        HStack(spacing: 3) {
                            ForEach(0..<24) { _ in
                                Rectangle()
                                    .fill(Color(white: 0.28))
                                    .frame(width: 1.5, height: 8)
                            }
                        }
                        .padding(.bottom, 4)
                    )
            }
            
            // Top subtle air intake grill grooves
            VStack {
                HStack(spacing: 6) {
                    ForEach(0..<8) { _ in
                        Capsule()
                            .fill(Color(white: 0.76))
                            .frame(width: 12, height: 2)
                    }
                }
                .padding(.top, 6)
                Spacer()
            }
            
            // Front subtle brand crease line
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(white: 0.78))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
            
            // LED Digital Display on the front fascia
            HStack {
                Spacer()
                if isOn {
                    Text(targetTemp)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(white: 0.55))
                        .shadow(color: Color.white.opacity(0.4), radius: 2)
                        .padding(.trailing, 18)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - Motorized Vent Flap (Louver)
struct ACLouverFlap: View {
    let isOpen: Bool
    let airflow: AirflowMode
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.94), Color(white: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
            )
            .rotationEffect(.degrees(isOpen ? 22 : 0), anchor: .top)
            .scaleEffect(y: isOpen ? 1.0 : 0.6, anchor: .top)
            .shadow(color: Color.black.opacity(isOpen ? 0.35 : 0.1), radius: 3, x: 0, y: isOpen ? 3 : 1)
    }
}

// MARK: - Fluttering Dynamic Airflow Breeze Stream
struct AirflowBreezeView: View {
    let phase: Double
    let mode: ACMode
    let speed: FanSpeed
    let airflow: AirflowMode
    let isEco: Bool
    
    var activeColors: [Color] {
        if isEco {
            return [
                Color(red: 0.2, green: 0.9, blue: 0.5).opacity(0.8),
                Color(red: 0.15, green: 0.7, blue: 0.4).opacity(0.4),
                Color(red: 0.3, green: 1.0, blue: 0.6).opacity(0.15)
            ]
        }
        return mode.breezeColors
    }
    
    var body: some View {
        ZStack {
            // Layer 1: Broad soft ambient breeze glow
            BreezeWaveShape(phase: phase * 0.9, streamCount: 9, spread: 45)
                .fill(
                    LinearGradient(
                        colors: [
                            activeColors[0],
                            activeColors[1],
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 4)
                .opacity(0.7)
            
            // Layer 2: Defined crisp flowing air streamers
            BreezeWaveShape(phase: phase * 1.2, streamCount: 13, spread: 55)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            activeColors[0],
                            activeColors[2],
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.4
                )
                .opacity(0.85)
            
            // Layer 3: High-frequency secondary ripple gusts
            BreezeWaveShape(phase: phase * 1.5 + 1.2, streamCount: 7, spread: 35)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            activeColors[1],
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.0
                )
                .opacity(0.5)
        }
        .rotationEffect(airflowRotation)
    }
    
    private var airflowRotation: Angle {
        switch airflow {
        case .vertical:
            return .degrees(0)
        case .horizontal:
            return .degrees(sin(phase * 0.6) * 14)
        case .both3D:
            return .degrees(sin(phase * 0.8) * 18)
        case .fixed:
            return .degrees(0)
        }
    }
}

// Custom shape that generates realistic fluttering air streams spreading downward
struct BreezeWaveShape: Shape {
    var phase: Double
    var streamCount: Int
    var spread: CGFloat
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let topY: CGFloat = 0
        let bottomY = rect.height
        
        let count = max(streamCount, 3)
        let startSpread: CGFloat = 160.0
        let startSpacing = startSpread / CGFloat(count - 1)
        
        for i in 0..<count {
            let offsetIndex = CGFloat(i) - CGFloat(count - 1) / 2.0
            let startX = centerX + offsetIndex * (startSpacing * 0.88)
            
            // Dynamic sway
            let waveAmp: CGFloat = 8.0 + abs(offsetIndex) * 2.5
            let sway = sin(phase + Double(i) * 0.45) * waveAmp
            
            let endX = centerX + offsetIndex * (startSpacing * 1.35) + sway
            
            let control1 = CGPoint(x: startX + sway * 0.3, y: topY + bottomY * 0.35)
            let control2 = CGPoint(x: endX - sway * 0.4, y: topY + bottomY * 0.7)
            
            path.move(to: CGPoint(x: startX, y: topY))
            path.addCurve(
                to: CGPoint(x: endX, y: bottomY),
                control1: control1,
                control2: control2
            )
        }
        
        return path
    }
}
