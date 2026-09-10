import QtQuick
import "../theme"

// Simple single-image wallpaper: loads one local image with a solid
// color fallback if it's missing or fails to load. Slideshow, video and
// remote images are deliberately out of scope here — that becomes
// NebulaWallpaperEngine's job later (see docs/Core-API.md, docs/Roadmap.md).
Rectangle {
    id: root

    required property NebulaThemeProvider theme

    property url source: ""
    // "fill" | "fit" | "crop" — maps to Image.fillMode.
    property string mode: "crop"

    // Fallback: this Rectangle's own fill color, always present
    // underneath — visible whenever there's no source, or the image
    // hasn't finished loading, or failed to load (Image.status !=
    // Ready). No error handling beyond that is needed: a failed Image
    // simply never becomes visible.
    color: theme.colors.backgroundColor

    readonly property int _fillMode: {
        switch (mode) {
        case "fill": return Image.Stretch
        case "fit": return Image.PreserveAspectFit
        default: return Image.PreserveAspectCrop
        }
    }

    Image {
        anchors.fill: parent
        source: root.source
        fillMode: root._fillMode
        asynchronous: true
        visible: status === Image.Ready

        // Diagnostic only — the fallback color above already handles
        // this case correctly for the user. Distinguishes "no source
        // provided" (must stay silent, the normal Template/dashboard-
        // prototype case) from "a source was given and failed to load"
        // (a typo'd asset path a theme author would otherwise have no
        // way to notice — Developer-Experience-Review-2026.md §6/§11).
        onStatusChanged: if (status === Image.Error && root.source.toString().length > 0) {
            console.warn("[NebulaWallpaper] Failed to load image:", root.source.toString())
        }
    }
}
