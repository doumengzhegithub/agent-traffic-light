import SwiftUI

struct TrafficLightView: View {
    @ObservedObject var viewModel: TrafficLightViewModel

    var body: some View {
        VStack(spacing: 8) {
            TrafficLightDot(
                color: .red,
                isActive: viewModel.overallState == .working
                    || viewModel.overallState == .error
            )
            TrafficLightDot(
                color: .yellow,
                isActive: viewModel.overallState == .waitingForUser
            )
            TrafficLightDot(
                color: .green,
                isActive: viewModel.overallState == .idle
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
        .help("\(viewModel.statusTitle): \(viewModel.statusDetail)")
        .frame(width: 52, height: 124)
    }
}
