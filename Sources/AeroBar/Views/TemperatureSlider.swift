import SwiftUI

public struct TemperatureSlider: View {
    @ObservedObject var state: ACState
    
    public init(state: ACState) {
        self.state = state
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                // Minus Stepper Button
                Button(action: {
                    state.stepTemperature(by: -1)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.16))
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(state.isOn ? 1.0 : 0.4)
                .disabled(!state.isOn)
                
                // Custom Slider Track
                GeometryReader { geo in
                    let trackWidth = geo.size.width
                    let thumbWidth: CGFloat = 46.0
                    let usableWidth = max(trackWidth - thumbWidth, 1.0)
                    
                    let minT = state.minTemperature
                    let maxT = state.maxTemperature
                    let progress = CGFloat((state.targetTemperature - minT) / (maxT - minT)).clamped(to: 0...1)
                    let thumbX = progress * usableWidth
                    
                    ZStack(alignment: .leading) {
                        // Slider Track Background
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(white: 0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        
                        // Active Warm/Cool Fill Gradient
                        if state.isOn {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(white: 0.35),
                                            Color(white: 0.28)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: thumbX + thumbWidth)
                        }
                        
                        // Tactile Rounded Pill Thumb
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        state.isOn ? Color(white: 0.88) : Color(white: 0.45),
                                        state.isOn ? Color(white: 0.74) : Color(white: 0.35)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: thumbWidth, height: 32)
                            .padding(.horizontal, 4)
                            .offset(x: thumbX)
                            .shadow(color: Color.black.opacity(state.isOn ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
                    }
                    .frame(height: 38)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard state.isOn else { return }
                                state.isDraggingSlider = true
                                let clampedX = value.location.x - (thumbWidth / 2.0)
                                let newProgress = CGFloat(clampedX / usableWidth).clamped(to: 0...1)
                                let newTemp = round(minT + Double(newProgress) * (maxT - minT))
                                if newTemp != state.targetTemperature {
                                    state.targetTemperature = newTemp
                                }
                            }
                            .onEnded { _ in
                                state.isDraggingSlider = false
                                SoundManager.shared.playBeep(isDouble: false)
                            }
                    )
                }
                .frame(height: 38)
                
                // Plus Stepper Button
                Button(action: {
                    state.stepTemperature(by: 1)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.16))
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(state.isOn ? 1.0 : 0.4)
                .disabled(!state.isOn)
            }
            
            // Slider Range Bounds Labels
            HStack {
                Spacer().frame(width: 54)
                Text("\(Int(state.minTemperature))°")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(white: 0.45))
                Spacer()
                Text("\(Int(state.maxTemperature))°")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(white: 0.45))
                Spacer().frame(width: 54)
            }
        }
    }
}
