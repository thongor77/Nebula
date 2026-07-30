import QtQuick

// Fake user backend for harnesses — proves NebulaUserService works with
// zero SDDM dependency.
QtObject {
    property var users: [
        { name: "nebula", displayName: "Nebula User", icon: "" }
    ]
    property var currentUser: users[0]

    function refresh() {}
}
