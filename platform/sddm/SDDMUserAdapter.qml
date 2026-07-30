import QtQuick

// Future contact point between NebulaUserService and the real SDDM
// `userModel` context property (`userModel.lastUser`, `userModel.lastIndex`
// — confirmed real API, see docs/Prototype-Results.md §3.2). Skeleton
// only: no real wiring yet — see docs/Services-Architecture.md.
QtObject {
    property var users: []
    property var currentUser: null

    function refresh() {
        console.warn("SDDMUserAdapter.refresh: not implemented yet (Phase 1.4 skeleton)")
    }
}
