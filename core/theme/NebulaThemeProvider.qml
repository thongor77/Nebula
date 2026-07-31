import QtQuick
import "../config"

// The only theming entry point Core components are allowed to consume
// (see DT-0006, docs/Theme-System.md, docs/Core-API.md). Wraps
// NebulaThemeConfig and re-exposes its token groups under a stable API,
// so the storage mechanism (DT-0003) can change later without touching
// any component.
QtObject {
    id: root

    // Until NebulaThemeLoader exists (see docs/Roadmap.md, Phase 1), this
    // *is* the fallback: NebulaThemeConfig's own defaults are the "minimal
    // theme" described in docs/Theme-System.md §5, not a separate case.
    property NebulaThemeConfig config: NebulaThemeConfig {}

    readonly property QtObject colors: config.colors
    readonly property QtObject spacing: config.spacing
    readonly property QtObject radius: config.radius
    readonly property QtObject typography: config.typography
    readonly property QtObject animation: config.animation
    readonly property QtObject overlay: config.overlay
    readonly property QtObject surface: config.surface
    readonly property QtObject interaction: config.interaction

    // Asset exposure (fonts/icons resolved by a real theme) is deferred
    // until NebulaThemeLoader exists — placeholder kept empty on purpose.
    readonly property QtObject assets: QtObject {}

    readonly property bool ready: config.valid
}
