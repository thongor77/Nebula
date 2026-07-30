import QtQuick

// Public contract for user data — current user, display name, avatar
// source. Components depend on this, never on SDDM's `userModel`
// directly (see docs/Nebula-Principles.md). Delegates to a swappable
// `adapter` (duck-typed: must expose `users` (list), `currentUser`
// (object), `refresh()`) — a mock adapter in tests, a real
// SDDMUserAdapter later (see docs/Services-Architecture.md).
//
// Multiple users are already modeled (`users`, a list) even though only
// a single current user matters for the Core MVP login screen — see
// docs/Roadmap.md, Phase 1.4.
QtObject {
    id: root

    property var adapter: null

    readonly property var users: adapter ? adapter.users : []
    readonly property var currentUser: adapter ? adapter.currentUser : null

    function refresh() {
        if (adapter && adapter.refresh) {
            adapter.refresh()
        }
    }
}
