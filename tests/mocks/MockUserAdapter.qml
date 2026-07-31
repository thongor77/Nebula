import QtQuick

// Fake user backend for harnesses — proves NebulaUserService works with
// zero SDDM dependency.
QtObject {
    // Three users — enough to actually exercise NebulaUserList's keyboard
    // navigation and mouse selection, not just instantiation with a
    // single trivial entry (found necessary in Phase 2.3, see
    // docs/Login-Architecture.md).
    property var users: [
        { name: "nebula", displayName: "Nebula User", icon: "" },
        { name: "alice", displayName: "Alice", icon: "" },
        { name: "bob", displayName: "Bob", icon: "" }
    ]
    property var currentUser: users[0]

    function refresh() {}
}
