import Foundation

/// Smooth acceleration and deceleration with zero velocity and acceleration at either end.
public enum FloatingVideoEasing {
    public static func progress(_ fraction: Double) -> Double {
        guard fraction.isFinite, fraction > 0 else { return 0 }
        guard fraction < 1 else { return 1 }
        return fraction * fraction * fraction * (fraction * (fraction * 6 - 15) + 10)
    }
}
