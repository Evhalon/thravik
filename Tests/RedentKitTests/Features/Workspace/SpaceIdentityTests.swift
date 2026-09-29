import Foundation
import Testing
@testable import RedentKit

@Suite("Space identity")
struct SpaceIdentityTests {
    @Test("Starter Spaces resolve to distinct preset looks")
    func starterPresets() {
        let looks = BrowserSpace.starterSpaces.map {
            SpaceIdentity.look(id: $0.id, icon: $0.icon, colorToken: $0.colorToken)
        }
        #expect(looks[0] == SpaceIdentity.work)
        #expect(looks[1] == SpaceIdentity.personal)
        #expect(looks[2] == SpaceIdentity.research)
        #expect(looks[3] == SpaceIdentity.travel)
        #expect(Set(looks.map(\.colorToken)).count == 4)
        #expect(Set(looks.map(\.icon)).count == 4)
    }

    @Test("Historical square/blue on a custom Space derives a stable look")
    func unsetCustomDerives() {
        let id = UUID(uuid: (0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
                             0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0x14, 0x03))
        let first = SpaceIdentity.look(id: id, icon: SpaceIdentity.unsetIcon, colorToken: SpaceIdentity.unsetToken)
        let second = SpaceIdentity.look(id: id, icon: SpaceIdentity.unsetIcon, colorToken: SpaceIdentity.unsetToken)
        #expect(first == second)
        #expect(first.icon == SpaceIdentity.icons[Int(id.uuid.14) % SpaceIdentity.icons.count])
        #expect(first.colorToken == SpaceIdentity.tokens[Int(id.uuid.15) % SpaceIdentity.tokens.count])
        #expect(first != SpaceIdentity.work)
    }

    @Test("An explicit icon and token on a custom Space is kept")
    func explicitLookPreserved() {
        let id = UUID()
        let look = SpaceIdentity.look(id: id, icon: "moon.fill", colorToken: "coral")
        #expect(look.icon == "moon.fill")
        #expect(look.colorToken == "coral")
    }

    @Test("New Spaces persist a resolved identity instead of square/blue")
    func newSpaceStoresResolvedLook() {
        let space = BrowserSpace(name: "Studio")
        #expect(space.icon != SpaceIdentity.unsetIcon)
        #expect(space.colorToken != SpaceIdentity.unsetToken)
        #expect(space.icon == SpaceIdentity.derived(from: space.id).icon)
    }
}
