import QtQuick

// Real binding between NebulaSessionService and the SDDM `sessionModel`
// context property — confirmed real API, see docs/Prototype-Results.md
// §3.2 and docs/Development-Journal.md, 2026-08-02 — Phase 3.2 (3.2.2).
// `sessionModel` is a QAbstractItemModel, not a plain object — like
// `screenModel` in Phase 1.0 (see Prototype-Results.md §3.3), it must be
// materialized through an `Instantiator`, never read as
// `sessionModel[i]` directly. Only one role is confirmed real,
// `name` — used directly as display text by the real `breeze` theme
// (`SessionButton.qml`, running in production on this machine): no
// separate machine id vs. display-name distinction exists, so both
// fields below carry the same value (a real, documented limitation, not
// an oversight).
//
// `selectSession()` only updates `currentIndex` locally — it does not
// call anything on `sddm` itself. The real session launch happens
// through `SDDMAuthAdapter`'s `sddm.login(username, password,
// sessionIndex)` call (Phase 3.2.4, see DT-0024 in
// docs/Decisions-Techniques.md), exactly mirroring how the real `breeze`
// theme's own `SessionButton.qml` behaves (its menu selection also only
// updates a local `currentIndex`, never touches `sddm` on its own).
//
// Item, not QtObject: needs a child `Instantiator`, and QtObject has no
// default property to hold one (see MockAuthAdapter, same workaround,
// docs/Development-Journal.md, Phase 1.4). Never shown on screen, so the
// visual baggage of Item is harmless here.
Item {
    id: root

    property var sessions: []
    property int currentIndex: -1

    function selectSession(index) {
        if (index >= 0 && index < root.sessions.length) {
            root.currentIndex = index
        }
    }

    Component.onCompleted: {
        root.currentIndex = sessionModel.lastIndex
    }

    Instantiator {
        model: sessionModel

        delegate: QtObject {
            readonly property string name: model.name
        }

        onObjectAdded: (index, object) => {
            var list = root.sessions.slice()
            list[index] = { name: object.name, displayName: object.name }
            root.sessions = list
        }

        onObjectRemoved: (index, object) => {
            var list = root.sessions.slice()
            list.splice(index, 1)
            root.sessions = list
        }
    }
}
