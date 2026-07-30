import QtQuick

// The visual root every theme's Main.qml starts from. Occupies the full
// available surface and hosts every other visual layer (NebulaWallpaper,
// NebulaOverlay, NebulaLoginLayout, ...) as ordinary children. Contains
// no theme logic, no image loading, no color of its own — see
// docs/Core-API.md and docs/Rendering-Guidelines.md. Deliberately this
// simple: a single anchored Item, nothing else.
Item {
    anchors.fill: parent
}
