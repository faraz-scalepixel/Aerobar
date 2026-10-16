import SwiftUI

public struct FeatureCardsRow: View {
    @ObservedObject var state: ACState
    
    public init(state: ACState) {
        self.state = state
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Card 1: Mode Picker
            Menu {
                ForEach(ACMode.allCases) { mode in
                    Button(action: {
                        state.mode = mode
                        SoundManager.shared.playBeep(isDouble: false)
                    }) {
                        HStack {
                            Text(mode.rawValue)
                            if state.mode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                FeatureCard(
                    icon: state.mode.iconName,
                    title: "Mode",
                    value: state.mode.rawValue,
                    hasChevron: true,
                    isActive: state.isOn
                )
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .disabled(!state.isOn)
            
            // Card 2: Fan Speed Picker
            Menu {
                ForEach(FanSpeed.allCases) { speed in
                    Button(action: {
                        state.fanSpeed = speed
                        SoundManager.shared.playBeep(isDouble: false)
                    }) {
                        HStack {
                            Text(speed.rawValue)
                            if state.fanSpeed == speed {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                SpinningFanCard(
                    speed: state.fanSpeed,
                    isActive: state.isOn
                )
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .disabled(!state.isOn)
            
            // Card 3: Sleep Timer
            Menu {
                ForEach(SleepDuration.allCases) { duration in
                    Button(action: {
                        state.sleepMode = duration
                        SoundManager.shared.playBeep(isDouble: false)
                    }) {
                        HStack {
                            Text(duration.rawValue)
                            if state.sleepMode == duration {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                FeatureCard(
                    icon: "moon.fill",
                    title: "Sleep",
                    value: state.sleepMode.rawValue,
                    hasDot: true,
                    isDotActive: state.sleepMode != .off,
                    isActive: state.isOn
                )
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .disabled(!state.isOn)
            
            // Card 4: Airflow Swing
            Menu {
                ForEach(AirflowMode.allCases) { flow in
                    Button(action: {
                        state.airflow = flow
                        SoundManager.shared.playBeep(isDouble: false)
                    }) {
                        HStack {
                            Text(flow.rawValue)
                            if state.airflow == flow {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                FeatureCard(
                    icon: "wind",
                    title: "Airflow",
                    value: state.airflow.rawValue,
                    hasChevron: true,
                    isActive: state.isOn
                )
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .disabled(!state.isOn)
        }
        .opacity(state.isOn ? 1.0 : 0.45)
    }
}

// MARK: - Reusable Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let value: String
    var hasChevron: Bool = false
    var hasDot: Bool = false
    var isDotActive: Bool = false
    var isActive: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.8))
                
                Spacer()
                
                if hasChevron {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(white: 0.45))
                }
                
                if hasDot {
                    Circle()
                        .fill(isDotActive ? Color.green : Color(white: 0.3))
                        .frame(width: 5, height: 5)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(white: 0.5))
            
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 74)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Animated Spinning Fan Card
struct SpinningFanCard: View {
    let speed: FanSpeed
    let isActive: Bool
    
    var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let angle = (date.truncatingRemainder(dividingBy: speed.rotationSpeed) / speed.rotationSpeed) * 360.0
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "fanblades")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(white: 0.8))
                        .rotationEffect(.degrees(isActive ? angle : 0))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(white: 0.45))
                }
                
                Spacer()
                
                Text("Fan speed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(white: 0.5))
                
                Text(speed.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 74)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}
