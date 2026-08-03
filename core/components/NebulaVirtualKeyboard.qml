import QtQuick
import "../theme"

// On-screen keyboard for password entry — fixes VK-001 (see
// docs/Investigations/VK-001-VirtualKeyboard.md). Hosts a real
// QtQuick.VirtualKeyboard.InputPanel via the internal, lazily-loaded
// NebulaInputPanel.qml, so Qt registers an AppInputPanel instead of
// falling back to its own detached, fixed-size DesktopInputPanel. See
// docs/Core-API.md for the full contract.
//
// Shown/hidden only through show()/hide()/toggle() — never automatically
// on focus. `available` is false (and the loaded item stays null) when
// qt6-virtualkeyboard isn't installed; a theme is expected to hide its
// toggle button in that case rather than assume the keyboard exists.
Item {
    id: root

    required property NebulaThemeProvider theme
    required property Item screenRoot
    // Refocused whenever the panel becomes active, so virtual keystrokes
    // land there instead of being eaten (mirrors breeze's
    // VirtualKeyboardLoader.qml, same rationale).
    property Item passwordField: null

    readonly property bool available: loader.status === Loader.Ready
    // Driven by root.state, not loader.item.active: the latter also
    // depends on Qt's own InputMethod.visible, an async platform signal
    // that can lag behind root.state (set synchronously by show()/hide()).
    // That lag raced against NebulaLoginLayout.bottomInset — the keyboard
    // panel could already be sliding into view while reservedHeight was
    // still 0, covering the login form instead of making room for it.
    readonly property bool keyboardActive: root.state === "visible"
    readonly property real reservedHeight: keyboardActive ? height : 0

    function show() { root.state = "visible" }
    function hide() { root.state = "hidden" }
    function toggle() { root.state = root.state === "hidden" ? "visible" : "hidden" }

    // Usually a bad idea for a top-level component, but this is tightly
    // coupled to its screen root by construction (same exception breeze
    // documents for VirtualKeyboardLoader.qml).
    anchors.left: parent.left
    anchors.right: parent.right
    height: loader.height
    state: "hidden"

    Loader {
        id: loader
        anchors.left: parent.left
        anchors.right: parent.right
        source: Qt.resolvedUrl("NebulaInputPanel.qml")
    }

    onKeyboardActiveChanged: if (keyboardActive && root.passwordField) {
        root.passwordField.forceActiveFocus()
    }

    states: [
        State {
            name: "visible"
            PropertyChanges { root.y: root.screenRoot.height - root.height }
        },
        State {
            name: "hidden"
            PropertyChanges { root.y: root.screenRoot.height }
        }
    ]

    transitions: [
        Transition {
            from: "hidden"; to: "visible"
            SequentialAnimation {
                ScriptAction {
                    script: {
                        if (loader.item) loader.item.activated = true
                        Qt.inputMethod.show()
                    }
                }
                NumberAnimation {
                    target: root
                    property: "y"
                    duration: root.theme.animation.durationNormal
                    easing.type: Easing.OutQuad
                }
            }
        },
        Transition {
            from: "visible"; to: "hidden"
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "y"
                    duration: root.theme.animation.durationNormal
                    easing.type: Easing.InQuad
                }
                ScriptAction {
                    script: {
                        if (loader.item) loader.item.activated = false
                        Qt.inputMethod.hide()
                    }
                }
            }
        }
    ]
}
