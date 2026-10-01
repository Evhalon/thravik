import RedentDesign
import SwiftUI

/// Film grain over a Space's color, scaled from the grain dial. At zero it
/// adds no layer at all, so a smooth Space pays nothing for the feature.
struct SpaceGrain: View {
    let amount: Double

    var body: some View {
        if amount > 0 {
            NoiseOverlay(opacity: min(amount * 1.4, 1))
        }
    }
}
