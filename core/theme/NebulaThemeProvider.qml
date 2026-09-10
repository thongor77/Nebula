import QtQuick
import "../config"

// The only theming entry point Core components are allowed to consume
// (see DT-0006, docs/Theme-System.md, docs/Core-API.md). Wraps
// NebulaThemeConfig and re-exposes its token groups under a stable API,
// so the storage mechanism (DT-0003) can change later without touching
// any component.
QtObject {
    id: root

    // Populated by NebulaThemeLoader (see docs/ThemeLoader.md, Phase
    // 2.0.5) — every real theme reassigns this to
    // `themeLoader.config`. NebulaThemeConfig's own defaults (used if a
    // theme never does this) are the "minimal theme" described in
    // docs/Theme-System.md §5, not a separate fallback case.
    property NebulaThemeConfig config: NebulaThemeConfig {}

    readonly property QtObject colors: config.colors
    readonly property QtObject spacing: config.spacing
    readonly property QtObject radius: config.radius
    readonly property QtObject typography: config.typography
    readonly property QtObject animation: config.animation
    readonly property QtObject overlay: config.overlay
    readonly property QtObject surface: config.surface
    readonly property QtObject interaction: config.interaction

    // Empty on purpose: NebulaThemeConfig has no `assets` group to
    // populate — asset exposure (fonts/icons resolved by a real theme)
    // is deferred until a real cross-theme need demonstrates what shape
    // it should take, not blocked on NebulaThemeLoader (which already
    // exists, see docs/ThemeLoader.md).
    readonly property QtObject assets: QtObject {}

    readonly property bool ready: config.valid
}
