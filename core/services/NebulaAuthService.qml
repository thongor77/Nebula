import QtQuick

// Public contract for authentication — components depend on this, never
// on SDDM directly (see docs/Nebula-Principles.md, docs/Core-API.md §1).
// Delegates to a swappable `adapter` (duck-typed: must expose
// `login(username, password, sessionIndex)`, `cancel()`, and signal
// `loginResult(bool success, string reason)`) — a mock adapter in tests,
// a real SDDMAuthAdapter later (see docs/Services-Architecture.md).
//
// Real `sddm.login()` wired in Phase 3.2.4 (see docs/Roadmap.md).
QtObject {
    id: root

    // QtObject has no default property, so a declarative `Connections {}`
    // child (which needs one) doesn't work here the way it would on an
    // Item — connecting imperatively in JS instead. Found by actually
    // running this file, not by qmllint (see docs/Development-Journal.md,
    // Phase 1.4).
    property var adapter: null
    onAdapterChanged: {
        if (adapter && adapter.loginResult) {
            adapter.loginResult.connect(_handleLoginResult)
        }
    }

    // Optional reference to a NebulaSessionService — when set, its
    // `currentIndex` is read at call time and forwarded to the adapter
    // so the real `sddm.login(username, password, sessionIndex)` call
    // launches the session the user actually selected, not just
    // whatever `sessionModel.lastIndex` defaulted to. Added in Phase
    // 3.2 without changing `authenticate()`'s public signature — see
    // DT-0024 in docs/Decisions-Techniques.md.
    property var sessionService: null

    readonly property bool authenticating: _authenticating
    readonly property string errorMessage: _errorMessage

    property bool _authenticating: false
    property string _errorMessage: ""

    signal succeeded()
    signal failed(string reason)

    function authenticate(username, password) {
        if (!adapter) {
            _errorMessage = "No auth adapter configured"
            failed(_errorMessage)
            return
        }
        _authenticating = true
        _errorMessage = ""
        var sessionIndex = sessionService ? sessionService.currentIndex : -1
        adapter.login(username, password, sessionIndex)
    }

    function cancel() {
        _authenticating = false
        if (adapter && adapter.cancel) {
            adapter.cancel()
        }
    }

    function _handleLoginResult(success, reason) {
        _authenticating = false
        if (success) {
            _errorMessage = ""
            succeeded()
        } else {
            _errorMessage = reason
            failed(reason)
        }
    }
}
