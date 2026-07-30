import QtQuick

// Fake session backend for harnesses — proves NebulaSessionService works
// with zero SDDM dependency.
QtObject {
    id: root

    property var sessions: [
        { name: "plasma", displayName: "Plasma (Wayland)" },
        { name: "plasmax11", displayName: "Plasma (X11)" }
    ]
    property int currentIndex: 0

    function selectSession(index) {
        root.currentIndex = index
    }
}
