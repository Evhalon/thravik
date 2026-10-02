import WebKit

@MainActor
struct FindPageSnapshot {
    struct Section {
        let path: [Int]
        let frame: WKFrameInfo?
        let range: Range<Int>
        let candidate: Int
    }

    struct Location {
        let path: [Int]
        let frame: WKFrameInfo?
        let localIndex: Int
    }

    var sections: [Section] = []
    var total: Int { sections.reduce(0) { $0 + $1.range.count } }

    func containsCandidate(in path: [Int]) -> Bool {
        sections.contains { $0.path == path && $0.range.contains($0.candidate) }
    }

    func location(at index: Int) -> Location? {
        var remaining = index
        for section in sections {
            if remaining < section.range.count {
                return Location(path: section.path, frame: section.frame,
                                localIndex: section.range.lowerBound + remaining)
            }
            remaining -= section.range.count
        }
        return nil
    }

    func candidateIndex(in path: [Int]? = nil, backward: Bool = false) -> Int {
        var offset = 0
        var candidates: [Int] = []
        for section in sections {
            if section.range.contains(section.candidate), path == nil || section.path == path {
                candidates.append(offset + section.candidate - section.range.lowerBound)
            }
            offset += section.range.count
        }
        return (backward ? candidates.last : candidates.first) ?? (backward ? max(0, total - 1) : 0)
    }
}
