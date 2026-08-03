import QtQuick

// Real binding between NebulaUserService and the SDDM `userModel`
// context property — confirmed real API, see docs/Prototype-Results.md
// §3.2 and docs/Development-Journal.md, 2026-08-02 — Phase 3.2 (3.2.0).
// `userModel` is a QAbstractItemModel — same `Instantiator` + explicit
// `model.<role>` pattern as `SDDMSessionAdapter` (3.2.2); a bare role
// identifier in a QtObject delegate does not auto-populate here
// (confirmed the hard way in 3.2.2, see Development-Journal.md).
//
// Only `name` (real system username — required as-is for
// `sddm.login()`), `realName` (human display name, falls back to `name`
// if empty, same logic as the real `breeze` theme's `UserList.qml`) and
// `icon` are mapped: `NebulaUserList`/`NebulaAvatar` only ever read
// `.name`/`.displayName`/`.icon` (see Core-API.md) — the other roles
// confirmed in `userModel` (`homeDir`, `needsPassword`, `vtNumber`, ...)
// have no consumer in the current Core component contract, so they are
// not carried over.
//
// Item, not QtObject: needs a child `Instantiator` (same constraint as
// `MockAuthAdapter`/`SDDMSessionAdapter`). Never shown on screen, so the
// visual baggage of Item is harmless here.
Item {
    id: root

    property var users: []
    readonly property var currentUser: (root._currentIndex >= 0 && root._currentIndex < root.users.length)
        ? root.users[root._currentIndex] : null

    property int _currentIndex: -1

    function refresh() {
        // userModel is populated once by SDDM before Main.qml loads —
        // same as sessionModel/screenModel (see Prototype-Results.md
        // §3.2/§3.3) — nothing to trigger manually.
    }

    Component.onCompleted: {
        root._currentIndex = userModel.lastIndex
    }

    Instantiator {
        model: userModel

        delegate: QtObject {
            readonly property string name: model.name
            readonly property string realName: model.realName
            readonly property string icon: model.icon
        }

        onObjectAdded: (index, object) => {
            var list = root.users.slice()
            list[index] = {
                name: object.name,
                displayName: object.realName || object.name,
                icon: object.icon
            }
            root.users = list
        }

        onObjectRemoved: (index, object) => {
            var list = root.users.slice()
            list.splice(index, 1)
            root.users = list
        }
    }
}
