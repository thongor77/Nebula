import QtQuick

// Future contact point between NebulaAuthService and the real SDDM
// `sddm` context property (`sddm.login(username, password, sessionIndex)`
// — confirmed real API, see docs/Prototype-Results.md §3.2). Skeleton
// only: no real `sddm.login()` call yet — see docs/Roadmap.md, Phase 1.4
// and docs/Services-Architecture.md for when this gets wired for real.
//
// Not Nebula-prefixed: this lives in platform/, not core/ — it is a
// concrete, SDDM-specific binding, not a reusable Core abstraction (see
// docs/Decisions-Techniques.md, DT-0010).
QtObject {
    signal loginResult(bool success, string reason)

    function login(username, password) {
        console.warn("SDDMAuthAdapter.login: not implemented yet (Phase 1.4 skeleton) — see docs/Services-Architecture.md")
    }

    function cancel() {
        console.warn("SDDMAuthAdapter.cancel: not implemented yet (Phase 1.4 skeleton)")
    }
}
