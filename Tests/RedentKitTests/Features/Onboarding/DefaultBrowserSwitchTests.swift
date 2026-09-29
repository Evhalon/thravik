import Testing
@testable import RedentKit

@Suite("Default browser switch")
struct DefaultBrowserSwitchTests {
    private enum Refused: Error { case panelRaised }

    /// macOS reports an error while its panel is still on screen. Reading the
    /// answer straight from that error called a switch that worked a failure.
    @Test("A thrown request still waits for Launch Services")
    func thrownRequestStillReadsBack() async {
        var reads = 0
        let switched = await DefaultBrowserSwitch.apply(
            request: { throw Refused.panelRaised },
            probes: .init(
                isDefault: {
                    reads += 1
                    return reads > 3
                },
                isPanelUp: { true },
                wait: {}
            )
        )

        #expect(switched)
    }

    /// The panel stays up longer than any fixed grace, so a switch answered
    /// late is still a switch.
    @Test("A panel left open holds the read-back open with it")
    func waitsWhileThePanelIsUp() async {
        var reads = 0
        let switched = await DefaultBrowserSwitch.apply(
            request: {},
            probes: .init(
                isDefault: {
                    reads += 1
                    return reads > DefaultBrowserSwitch.graceAttempts + 10
                },
                isPanelUp: { true },
                wait: {}
            )
        )

        #expect(switched)
    }

    /// An answered panel that left the old handler in place is a no, and the
    /// person who said it should not watch the rest of the window run out.
    @Test("A closed panel and the old handler ends the wait early")
    func stopsShortlyAfterThePanelCloses() async {
        var reads = 0
        let switched = await DefaultBrowserSwitch.confirm(
            probes: .init(
                isDefault: {
                    reads += 1
                    return false
                },
                isPanelUp: { reads <= 2 },
                wait: {}
            )
        )

        #expect(!switched)
        #expect(reads == 2 + DefaultBrowserSwitch.graceAttempts)
    }

    /// Launch Services publishes the change a moment behind the click, so the
    /// reads after the panel closes are the ones that catch a yes.
    @Test("A yes published just after the panel closes still counts")
    func catchesTheChangeInTheGrace() async {
        var reads = 0
        let switched = await DefaultBrowserSwitch.confirm(
            probes: .init(
                isDefault: {
                    reads += 1
                    return reads > DefaultBrowserSwitch.graceAttempts
                },
                isPanelUp: { reads < 2 },
                wait: {}
            )
        )

        #expect(switched)
    }

    @Test("A window that closes with no panel ever seen is a no")
    func givesUpAfterTheWindow() async {
        var waits = 0
        let switched = await DefaultBrowserSwitch.apply(
            attempts: 4,
            request: {},
            probes: .init(isDefault: { false }, isPanelUp: { false }, wait: { waits += 1 })
        )

        #expect(!switched)
        #expect(waits == 3)
    }

    @Test("Already the default answers without waiting")
    func answersImmediatelyWhenAlreadyDefault() async {
        var waits = 0
        let switched = await DefaultBrowserSwitch.apply(
            request: {},
            probes: .init(isDefault: { true }, isPanelUp: { false }, wait: { waits += 1 })
        )

        #expect(switched)
        #expect(waits == 0)
    }
}
