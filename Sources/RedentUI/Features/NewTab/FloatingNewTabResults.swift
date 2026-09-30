import RedentDesign
import SwiftUI

struct FloatingNewTabResults: View {
    static let maximumHeight: CGFloat = 340

    let items: [FloatingNewTabItem]
    let showsSections: Bool
    let selectedIndex: Int
    let onSelect: (FloatingNewTabItem) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if showsSections && startsSection(at: index) {
                            Text(item.section.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Palette.chromeSecondaryText)
                                .padding(.horizontal, 14)
                                .padding(.top, index == 0 ? 6 : 12)
                                .padding(.bottom, 3)
                        }
                        FloatingNewTabRow(item: item, isSelected: index == selectedIndex) {
                            onSelect(item)
                        }
                        .id(item.id)
                    }
                }
                .padding(9)
            }
            .scrollIndicators(.hidden)
            .frame(height: resultsHeight)
            .onChange(of: selectedIndex) { _, index in
                guard items.indices.contains(index) else { return }
                withAnimation(.easeOut(duration: 0.16)) { proxy.scrollTo(items[index].id) }
            }
        }
    }

    private func startsSection(at index: Int) -> Bool {
        index == 0 || items[index - 1].section != items[index].section
    }

    private var resultsHeight: CGFloat {
        let headers = showsSections ? items.indices.filter(startsSection).count : 0
        return min(Self.maximumHeight, CGFloat(items.count * 62 + headers * 30 + 18))
    }
}
