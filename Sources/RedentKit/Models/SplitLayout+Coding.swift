import Foundation

/// Anything that does not describe a valid split restores as no split, rather
/// than as a pane drawn at zero width. The two-pane layout earlier builds saved
/// never recorded its first tab, so it cannot be rebuilt and starts unsplit.
extension SplitLayout: Codable {
    private enum CodingKeys: String, CodingKey {
        case tabIDs, orientation, fractions
    }

    public init(from decoder: any Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        orientation = (try? values.decodeIfPresent(Orientation.self, forKey: .orientation)) ?? .horizontal
        let ids = (try? values.decodeIfPresent([UUID].self, forKey: .tabIDs)) ?? []
        guard ids.count > 1, Set(ids).count == ids.count else { return }
        tabIDs = Array(ids.prefix(Self.maximumPanes))
        let stored = (try? values.decodeIfPresent([Double].self, forKey: .fractions)) ?? []
        if stored.count == paneCount, stored.allSatisfy({ $0 >= Self.minimumFraction }) {
            let total = stored.reduce(0, +)
            fractions = stored.map { $0 / total }
        } else {
            fractions = Array(repeating: 1 / Double(paneCount), count: paneCount)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(tabIDs, forKey: .tabIDs)
        try values.encode(orientation, forKey: .orientation)
        try values.encode(fractions, forKey: .fractions)
    }
}
