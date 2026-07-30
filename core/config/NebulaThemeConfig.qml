import QtQuick

// Container for the active theme's resolved token values (Design System
// vocabulary — see docs/Design-System.md). No loading logic, no
// distribution logic: NebulaThemeLoader will populate this later,
// NebulaThemeProvider is the only thing components are allowed to read
// from (see DT-0006, docs/Theme-System.md).
//
// The values below are the Core's own neutral fallback ("minimal theme"
// from docs/Theme-System.md §5), deliberately NOT the Nord palette —
// Core must never carry a specific theme's identity (docs/Core-API.md §1).
QtObject {
    id: root

    readonly property QtObject colors: QtObject {
        property color primaryColor: "#4a90d9"
        property color secondaryColor: "#6c7a89"
        // Deliberately distinct in hue from primaryColor — this is what
        // makes a focus ring visible on a primary-colored button (see
        // docs/Core-Implementation-Status.md, bug found during testing).
        property color accentColor: "#f0a030"
        property color backgroundColor: "#1e1e1e"
        property color surfaceColor: "#2a2a2a"
        property color textPrimary: "#f0f0f0"
        property color textSecondary: "#a0a0a0"
        property color errorColor: "#d9534f"
        property color successColor: "#5cb85c"
    }

    readonly property QtObject spacing: QtObject {
        property real spacingXs: 4
        property real spacingSm: 8
        property real spacingMd: 16
        property real spacingLg: 24
        property real spacingXl: 32
    }

    readonly property QtObject radius: QtObject {
        property real radiusSmall: 4
        property real radiusMedium: 8
        property real radiusLarge: 16
        // Larger than any realistic element's half-height, so Qt Quick's
        // own radius clamping always yields a full pill/capsule shape.
        property real radiusPill: 9999
    }

    readonly property QtObject typography: QtObject {
        // Generic family names only — Core has no guarantee a specific
        // font is installed (see docs/SDDM-Compatibility.md).
        property string fontFamilyPrimary: "sans-serif"
        property string fontFamilySecondary: "sans-serif"
        property real fontSizeTitle: 24
        property real fontSizeBody: 14
        property real fontSizeClock: 32
        property int fontWeightNormal: Font.Normal
        property int fontWeightBold: Font.Bold
    }

    readonly property QtObject animation: QtObject {
        property int durationFast: 120
        property int durationNormal: 250
        property int durationSlow: 500
        // Easing curves deliberately not fixed yet — see
        // docs/Design-System.md §5 ("ne pas figer avant d'avoir testé
        // leur rendu réel à 60 FPS").
    }

    // Effects tokens (blurAmount, glowIntensity, particleDensity,
    // enableEffects, ...) are deliberately not implemented yet: no
    // component consumes them until Phase 3 (see docs/Roadmap.md).

    // Simple validation: every group must hold sane, usable values.
    // Not a full schema validator — just a sanity check that the
    // resolved config is fit to hand to components.
    readonly property bool valid: colors.primaryColor.a > 0
        && spacing.spacingMd > 0
        && radius.radiusMedium > 0
        && typography.fontSizeBody > 0
        && animation.durationNormal > 0
}
