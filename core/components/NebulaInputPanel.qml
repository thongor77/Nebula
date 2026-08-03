import QtQuick
import QtQuick.VirtualKeyboard as QtVK

// Internal implementation loaded by NebulaVirtualKeyboard.qml's Loader —
// never instantiated directly by a theme, not part of the public
// contract (see docs/Core-API.md §4).
//
// `width: parent.width` is the actual VK-001 fix (see
// docs/Investigations/VK-001-VirtualKeyboard.md): Qt Virtual Keyboard
// derives the panel's height from this width via the active style's
// aspect ratio, so binding a real per-screen width is the whole
// correction — without it (the status quo everywhere else in Nebula),
// Qt falls back to its own detached, fixed-size DesktopInputPanel.
//
// `InputMethod` (bare, no import) is a global exposed by the
// qtvirtualkeyboard platform input context once
// `QT_IM_MODULE=qtvirtualkeyboard` is active in the process environment
// — already true today under the real SDDM greeter, since that env var
// is exactly what produces the oversized DesktopInputPanel this
// component replaces. Mirrors KDE breeze's own
// org/kde/breeze/components/VirtualKeyboard.qml pattern.
QtVK.InputPanel {
    id: root

    property bool activated: false

    active: activated && InputMethod.visible
    width: parent ? parent.width : 0
}
