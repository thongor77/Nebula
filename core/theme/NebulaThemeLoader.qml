import QtQuick
import "../config"

// Sole owner of theme.conf loading (Phase 2.0.5, see docs/ThemeLoader.md).
// A pure adapter between a theme's files and NebulaThemeConfig — it
// never decides anything: no component knowledge, no theme identity, no
// business logic (see docs/Nebula-Principles.md #1/#2). Reads theme.conf
// directly via file I/O, never through SDDM's `config` context property
// — that would make Core depend on SDDM directly, forbidden by
// Nebula-Principles.md #2. Works identically under real SDDM, under
// `sddm-greeter --test-mode`, and standalone via `qml6` (see
// docs/Compatibility-Matrix.md).
//
// Never crashes: any anomaly (missing file, unknown token, invalid
// value) is logged and the Core's own default for that token is kept —
// see §3 "Validation" in docs/ThemeLoader.md.
QtObject {
    id: root

    // Absolute file:// URL to a theme.conf. A theme's own Main.qml sets
    // this relative to itself, e.g. `Qt.resolvedUrl("theme.conf")` — no
    // indirection through a "theme name" is needed, since a theme's
    // Main.qml already knows its own location structurally.
    property url configPath: ""

    readonly property NebulaThemeConfig config: NebulaThemeConfig {}

    // Best-effort, derived from configPath's parent directory name —
    // purely informational (logging, docs/ThemeLoader.md), never used
    // for any loading decision.
    readonly property string themeName: {
        var parts = root.configPath.toString().split("/")
        return parts.length >= 2 ? parts[parts.length - 2] : ""
    }

    readonly property bool loaded: _loaded
    readonly property string loadError: _loadError

    property bool _loaded: false
    property string _loadError: ""

    // Caveat found while testing this component (see
    // docs/Development-Journal.md, Phase 2.0.5): if `configPath` is set
    // as a literal at the same time a NebulaThemeLoader is instantiated
    // (the common case), the very first load happens synchronously
    // during construction — before a `onThemeLoaded`/`onThemeLoadFailed`
    // handler declared in that same object literal is connected. That
    // first load is silently missed by such a handler. Always read
    // `loaded`/`loadError`/`config` directly instead (correct and
    // synchronous by the time any of your own code runs) — treat these
    // signals as useful only for a `configPath` change that happens
    // *after* construction (e.g. a manual `reload()` call later).
    signal themeLoaded()
    signal themeLoadFailed(string reason)

    onConfigPathChanged: root.reload()

    // Exposed for a harness/theme to force a re-read (e.g. after editing
    // theme.conf during development) — not automatic, no hot-reload
    // guarantee (see docs/Architecture.md, Inconnues critiques).
    function reload() {
        root._loaded = false
        root._loadError = ""

        if (root.configPath.toString().length === 0) {
            return
        }

        var flatValues
        try {
            flatValues = root._readIniGeneral(root.configPath)
        } catch (e) {
            root._loadError = e.toString()
            console.warn("[NebulaThemeLoader] FAILED to load", root.configPath.toString() + ":", root._loadError)
            root.themeLoadFailed(root._loadError)
            return
        }

        root._applyFlatValues(root.config, flatValues)
        root._loaded = true
        root.themeLoaded()
    }

    function _readIniGeneral(path) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", path, false)
        xhr.send()
        if (xhr.status !== 0 && xhr.status !== 200) {
            throw "HTTP status " + xhr.status + " reading " + path
        }
        if (xhr.status === 0 && xhr.responseText.length === 0) {
            // Local file:// XMLHttpRequest reports the exact same thing
            // (status 0, empty responseText) whether the file is missing,
            // genuinely empty, or local reads are disabled — no way to
            // tell these apart from here (verified real behavior, see
            // docs/Compatibility-Matrix.md). Flagged as a load error
            // rather than silently treated as "zero tokens, all good":
            // a typo'd configPath should be visible to a theme author,
            // not silently produce an unstyled theme.
            throw "nothing read from " + path + " -- file missing, empty, or local file " +
                "reads disabled (set QML_XHR_ALLOW_FILE_READ=1); Qt cannot distinguish these " +
                "for a local file (see docs/Compatibility-Matrix.md)"
        }
        var result = {}
        var lines = xhr.responseText.split("\n")
        var inGeneral = false
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0 || line[0] === ";" || line[0] === "#") continue
            if (line[0] === "[") {
                inGeneral = (line === "[General]")
                continue
            }
            if (!inGeneral) continue
            var eq = line.indexOf("=")
            if (eq === -1) continue
            var key = line.substring(0, eq).trim()
            var value = line.substring(eq + 1).trim()
            result[key] = value
        }
        return result
    }

    // `objectName`/`xxxChanged` are also own keys of every QtObject, not
    // real tokens (see docs/Development-Journal.md, Phase 1.6) — excluded
    // below, not just tokens actually present in theme.conf.
    function _applyFlatValues(target, flatValues) {
        var groupNames = Object.keys(target).filter((key) => {
            return typeof target[key] === "object" && target[key] !== null
        })
        for (var i = 0; i < groupNames.length; i++) {
            var group = target[groupNames[i]]
            var tokenNames = Object.keys(group).filter((key) => {
                return key !== "objectName" && typeof group[key] !== "function"
            })
            for (var j = 0; j < tokenNames.length; j++) {
                var tokenName = tokenNames[j]
                if (flatValues[tokenName] === undefined) {
                    continue
                }

                // "" + ... forces a real snapshot via toString(). Without
                // it, `var previous = group[tokenName]` captures a live
                // reference for object-typed properties (color, ...): it
                // silently reflects the *new* value too after the
                // assignment below, instead of staying the old one --
                // found for real (see docs/Development-Journal.md, Phase
                // 2.0.5) when reverting an invalid color logged the same
                // (wrong) value it was supposedly reverting to.
                var previous = "" + group[tokenName]
                group[tokenName] = flatValues[tokenName]
                var current = group[tokenName]

                var isInvalid = (typeof current === "number" && isNaN(current))
                    || (typeof current === "object" && current !== null
                        && current.valid === false)

                if (isInvalid) {
                    group[tokenName] = previous
                    console.warn("[NebulaThemeLoader] Invalid value for " + tokenName + ": \"" +
                        flatValues[tokenName] + "\" -- kept default (" + previous + ").")
                } else {
                    console.log("[NebulaThemeLoader] Loaded token: " + tokenName + " -> " + current)
                }
            }

            // Flag every theme.conf key that never matched any token in
            // any group, in a second pass (needs all groups' token names
            // gathered first — see below).
        }

        var allTokenNames = []
        for (var g = 0; g < groupNames.length; g++) {
            var groupObj = target[groupNames[g]]
            allTokenNames = allTokenNames.concat(Object.keys(groupObj).filter((key) => {
                return key !== "objectName" && typeof groupObj[key] !== "function"
            }))
        }
        var flatKeys = Object.keys(flatValues)
        for (var k = 0; k < flatKeys.length; k++) {
            if (allTokenNames.indexOf(flatKeys[k]) === -1) {
                console.warn("[NebulaThemeLoader] Unknown token: " + flatKeys[k] + " -- ignored.")
            }
        }
    }
}
