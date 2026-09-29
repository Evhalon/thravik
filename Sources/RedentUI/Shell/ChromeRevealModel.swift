import Foundation
import Observation

/// Hover state is transient: revealing chrome never changes saved layout.
@MainActor @Observable
final class ChromeRevealModel {
    enum Surface { case sidebar, navigation }
    enum Region: Hashable {
        case leftEdge, topEdge, sidebar, navigation

        var surface: Surface {
            switch self {
            case .leftEdge, .sidebar: .sidebar
            case .topEdge, .navigation: .navigation
            }
        }
    }

    private(set) var surface: Surface?
    @ObservationIgnored private(set) var dismissalTask: Task<Void, Never>?
    private var hoveredRegions: Set<Region> = []
    private var isLocked = false

    func hover(_ region: Region, isInside: Bool) {
        guard isInside else {
            hoveredRegions.remove(region)
            scheduleDismissal()
            return
        }
        hoveredRegions.insert(region)
        guard !isLocked || surface == nil || surface == region.surface else { return }
        dismissalTask?.cancel()
        surface = region.surface
    }

    func setLocked(_ locked: Bool) {
        isLocked = locked
        if locked { dismissalTask?.cancel() } else { scheduleDismissal() }
    }

    func reset() {
        dismissalTask?.cancel()
        dismissalTask = nil
        hoveredRegions.removeAll()
        surface = nil
        isLocked = false
    }

    private func scheduleDismissal() {
        guard let surface, !isLocked else { return }
        guard !hoveredRegions.contains(where: { $0.surface == surface }) else { return }
        dismissalTask?.cancel()
        // Gives the pointer time to cross from the edge into the sliding panel.
        dismissalTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(220)) } catch { return }
            guard let self, !self.isLocked else { return }
            guard !self.hoveredRegions.contains(where: { $0.surface == self.surface }) else { return }
            self.surface = nil
        }
    }
}
