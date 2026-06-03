import SwiftUI

struct TrafficLightDot: View {
    let color: Color
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(color.opacity(isActive ? 1 : 0.18))
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isActive ? 0.7 : 0.18), lineWidth: 1)
            )
            .shadow(
                color: color.opacity(isActive ? 0.7 : 0),
                radius: isActive ? 8 : 0
            )
            .frame(width: 28, height: 28)
    }
}
