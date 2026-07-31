import QtQuick
import "../theme"
import "../services"

// Exposes shutdown/reboot/suspend/hibernate — never calls
// `sddm.powerOff()`/`reboot()`/`suspend()`/`hibernate()` directly (see
// docs/Nebula-Principles.md §2/§6). Each action is a plain NebulaButton;
// only actions the current `NebulaPowerService` reports as available are
// shown. See docs/Core-API.md and docs/Login-Architecture.md for the
// full contract.
Item {
    id: root

    required property NebulaThemeProvider theme
    required property NebulaPowerService powerService
    // When true, a first click only arms the action (label becomes
    // "Confirm?"); a second click within `_confirmTimeout` actually
    // triggers it. No modal dialog exists in the Core yet
    // (NebulaNotification isn't built — see docs/Roadmap.md), so this
    // stays a self-contained, minimal confirmation rather than a dialog.
    property bool confirmBeforeAction: false

    // Text fallbacks, always available — a theme isn't required to
    // provide icons. Overridable for localization (Phase 3.1, see
    // docs/Core-Refinement-Review.md §6 — these were previously
    // hardcoded and untranslatable).
    property string shutdownLabel: "Shut Down"
    property string rebootLabel: "Restart"
    property string suspendLabel: "Sleep"
    property string hibernateLabel: "Hibernate"
    property string confirmLabel: "Confirm?"
    // Passed straight through to each action's NebulaButton.icon — a
    // theme isn't required to provide any (Phase 3.1, see
    // docs/Core-Refinement-Review.md §2).
    property url shutdownIcon: ""
    property url rebootIcon: ""
    property url suspendIcon: ""
    property url hibernateIcon: ""
    property real iconSize: theme.typography.fontSizeBody

    signal shutdownRequested()
    signal rebootRequested()
    signal suspendRequested()
    signal hibernateRequested()

    readonly property int _confirmTimeout: 3000
    property string _pendingAction: ""

    function _trigger(action, run, notify) {
        if (root.confirmBeforeAction && root._pendingAction !== action) {
            root._pendingAction = action
            confirmResetTimer.restart()
            return
        }
        root._pendingAction = ""
        confirmResetTimer.stop()
        run()
        notify()
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Timer {
        id: confirmResetTimer
        interval: root._confirmTimeout
        onTriggered: root._pendingAction = ""
    }

    Row {
        id: row
        spacing: root.theme.spacing.spacingSm

        NebulaButton {
            theme: root.theme
            visible: root.powerService.canShutdown
            variant: "secondary"
            label: root._pendingAction === "shutdown" ? root.confirmLabel : root.shutdownLabel
            icon: root.shutdownIcon
            iconSize: root.iconSize
            onClicked: root._trigger("shutdown",
                () => root.powerService.shutdown(),
                () => root.shutdownRequested())
        }

        NebulaButton {
            theme: root.theme
            visible: root.powerService.canReboot
            variant: "secondary"
            label: root._pendingAction === "reboot" ? root.confirmLabel : root.rebootLabel
            icon: root.rebootIcon
            iconSize: root.iconSize
            onClicked: root._trigger("reboot",
                () => root.powerService.reboot(),
                () => root.rebootRequested())
        }

        NebulaButton {
            theme: root.theme
            visible: root.powerService.canSuspend
            variant: "ghost"
            label: root._pendingAction === "suspend" ? root.confirmLabel : root.suspendLabel
            icon: root.suspendIcon
            iconSize: root.iconSize
            onClicked: root._trigger("suspend",
                () => root.powerService.suspend(),
                () => root.suspendRequested())
        }

        NebulaButton {
            theme: root.theme
            visible: root.powerService.canHibernate
            variant: "ghost"
            label: root._pendingAction === "hibernate" ? root.confirmLabel : root.hibernateLabel
            icon: root.hibernateIcon
            iconSize: root.iconSize
            onClicked: root._trigger("hibernate",
                () => root.powerService.hibernate(),
                () => root.hibernateRequested())
        }
    }
}
