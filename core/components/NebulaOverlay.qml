import QtQuick
import "../theme"

// A flat visual veil placed over whatever sits behind it (typically
// NebulaWallpaper) to improve text legibility. No blur, no ShaderEffect
// — a plain color or two-stop gradient fill only, kept deliberately
// cheap (see docs/Rendering-Guidelines.md).
Rectangle {
    id: root

    required property NebulaThemeProvider theme

    // Two-stop vertical gradient instead of a flat fill, e.g. to darken
    // just the bottom edge near a footer. Off (flat fill) by default.
    property bool useGradient: false
    property color color1: theme.colors.backgroundColor
    property color color2: "transparent"

    opacity: theme.overlay.overlayOpacity
    color: useGradient ? "transparent" : color1
    gradient: useGradient ? gradientDef : null

    Gradient {
        id: gradientDef
        GradientStop { position: 0.0; color: root.color1 }
        GradientStop { position: 1.0; color: root.color2 }
    }
}
