import QtQuick

// Future contact point between NebulaSessionService and the real SDDM
// `sessionModel` context property (`sessionModel.lastIndex`, populated
// from wayland-sessions/xsessions .desktop files — confirmed real API,
// see docs/Prototype-Results.md §3.2). Skeleton only: no real wiring yet
// — see docs/Services-Architecture.md.
QtObject {
    property var sessions: []
    property int currentIndex: -1

    function selectSession(index) {
        console.warn("SDDMSessionAdapter.selectSession: not implemented yet (Phase 1.4 skeleton)")
    }
}
