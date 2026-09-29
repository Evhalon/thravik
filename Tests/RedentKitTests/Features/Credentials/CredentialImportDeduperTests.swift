import Foundation
import RedentKit
import Testing

@Suite("Import skips logins already in the vault")
struct CredentialImportDeduperTests {
    private let origin = Origin(scheme: "https", host: "mail.google.com")

    @Test("A username already stored is not imported again")
    func skipsExistingUsername() {
        let existing = [Credential(origin: origin, username: "a", password: "1")]
        let found = [
            Credential(origin: origin, username: "a", password: "1"),
            Credential(origin: origin, username: "b", password: "2")
        ]
        let fresh = CredentialImportDeduper.newcomers(in: found, alreadyHave: existing)
        #expect(fresh.map(\.username) == ["b"])
    }

    @Test("Duplicates inside the import itself are collapsed")
    func collapsesInternalDuplicates() {
        let found = [
            Credential(origin: origin, username: "a", password: "1"),
            Credential(origin: origin, username: "a", password: "1")
        ]
        let fresh = CredentialImportDeduper.newcomers(in: found, alreadyHave: [])
        #expect(fresh.count == 1)
    }

    @Test("The same login from another Space is still a duplicate")
    func collapsesCrossSpaceDuplicates() {
        let existing = Credential(
            origin: origin, username: "a", password: "1", spaceID: BrowserSpace.workID
        )
        let found = Credential(
            origin: origin, username: "a", password: "2", spaceID: BrowserSpace.personalID
        )
        #expect(CredentialImportDeduper.newcomers(in: [found], alreadyHave: [existing]).isEmpty)
    }
}
