import QtQuick

// Public contract for session selection — available sessions, active
// session, switching. Components depend on this, never on SDDM's
// `sessionModel` directly (see docs/Nebula-Principles.md). Delegates to
// a swappable `adapter` (duck-typed: must expose `sessions` (list),
// `currentIndex` (int), `selectSession(index)`) — a mock adapter in
// tests, a real SDDMSessionAdapter later (see
// docs/Services-Architecture.md). No real SDDM logic yet.
QtObject {
    id: root

    property var adapter: null

    readonly property var sessions: adapter ? adapter.sessions : []
    readonly property int currentIndex: adapter ? adapter.currentIndex : -1

    signal sessionChanged(int index)

    function selectSession(index) {
        if (!adapter) {
            return
        }
        adapter.selectSession(index)
        sessionChanged(index)
    }
}
