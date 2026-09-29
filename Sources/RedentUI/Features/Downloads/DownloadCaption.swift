import RedentDesign
import RedentKit
import SwiftUI

/// The grey line under a download's name: where it came from and how much,
/// with an estimate of the time left while it runs.
struct DownloadCaption: View {
    let item: DownloadItem

    var body: some View {
        Text(text)
            .font(.system(size: 10.5).monospacedDigit())
            .foregroundStyle(isFailure ? Palette.danger : Palette.chromeSecondaryText)
            .lineLimit(1)
            .contentTransition(.numericText())
    }

    private var text: String {
        switch item.state {
        case .running: [item.sizeCaption, remaining].compactMap { $0 }.joined(separator: " · ")
        case .finished: [DownloadItem.format(item.bytesReceived), item.host]
            .compactMap { $0 }.joined(separator: " · ")
        case .cancelled: "Cancelled"
        case .failed(let reason): reason
        }
    }

    private var remaining: String? {
        guard let seconds = item.secondsRemaining(at: .now) else { return nil }
        let left = Duration.seconds(max(1, seconds.rounded())).formatted(
            .units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 1)
        )
        return "\(left) left"
    }

    private var isFailure: Bool {
        if case .failed = item.state { true } else { false }
    }
}
