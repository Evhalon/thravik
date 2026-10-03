extension TabController {
    /// The window closed. Releasing the hold here rather than in `deinit` keeps
    /// the ephemeral store's lifetime tied to the window the user closed, not to
    /// whenever the last view referencing this controller happens to go away.
    public func retire() {
        extensions?.detach(self)
        for tab in webTabs { tab.hibernate() }
        contexts.release(owner: ObjectIdentifier(self))
        warmer.discard()
    }
}
