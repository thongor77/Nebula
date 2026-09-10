import QtQuick
import "../theme"

// User avatar with an image and a graceful fallback — standalone
// (reused inside NebulaUserList later). See docs/Core-API.md.
Item {
    id: root

    required property NebulaThemeProvider theme

    property url source: ""
    property url fallbackIcon: ""
    property real size: 64
    // Corner radius used to clip the avatar — defaults to a full circle.
    property real radius: theme.radius.radiusPill

    implicitWidth: size
    implicitHeight: size

    readonly property bool hasImage: root.source.toString().length > 0
        && image.status === Image.Ready

    Rectangle {
        id: clip
        anchors.fill: parent
        radius: root.radius
        color: theme.colors.surfaceColor
        clip: true

        Image {
            id: image
            source: root.source
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            visible: root.hasImage
            asynchronous: true

            // Diagnostic only — the silhouette/fallbackIcon fallback
            // already handles this case correctly for the user.
            // Distinguishes "no source provided" (must stay silent) from
            // "a source was given and failed to load" (a typo'd user
            // avatar path — Developer-Experience-Review-2026.md §6/§11).
            onStatusChanged: if (status === Image.Error && root.source.toString().length > 0) {
                console.warn("[NebulaAvatar] Failed to load image:", root.source.toString())
            }
        }

        // Fallback icon supplied by the theme, shown only if no user
        // image is available (or it's still loading/failed).
        Image {
            source: root.fallbackIcon
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            visible: !root.hasImage && root.fallbackIcon.toString().length > 0
        }

        // Zero-asset generic silhouette — guarantees a visible fallback
        // even when the theme supplies no fallbackIcon at all.
        Item {
            anchors.fill: parent
            visible: !root.hasImage && root.fallbackIcon.toString().length === 0

            Rectangle {
                width: parent.width * 0.42
                height: width
                radius: width / 2
                color: theme.colors.textSecondary
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.18
            }

            Rectangle {
                width: parent.width * 0.7
                height: parent.height * 0.45
                radius: height / 2
                color: theme.colors.textSecondary
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -height * 0.25
            }
        }
    }
}
