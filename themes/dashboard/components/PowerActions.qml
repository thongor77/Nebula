import QtQuick
import "../../../core/theme"
import "../../../core/services"

// Theme-local (Dashboard only), reusing NebulaPowerService directly —
// deliberately NOT NebulaPowerButtons/NebulaButton, since the mockup
// this implements needs a plain-text presentation (no background/border
// at rest) that NebulaButton cannot currently express (see
// PowerTextAction.qml).
//
// Architectural observation: Dashboard requires a text-only action
// presentation not currently expressible by NebulaButton. Deliberately
// NOT promoted to Core — Dashboard is still an experimental/showcase
// theme and the Core API is frozen (docs/API-Stability-Review.md)
// pending a real, multi-theme-demonstrated need (the same bar that
// gated NebulaUserList.avatarSize earlier this session). If a second,
// independent theme later needs the same text-only interaction pattern,
// reconsider promoting a generic text/link NebulaButton variant then,
// with that stronger justification. Theme-local now, Core candidate
// later.
//
// Everything that isn't presentation goes straight through the existing
// NebulaPowerService — same contract NebulaPowerButtons itself uses, no
// platform logic duplicated here. Confirm-before-action, focus/hover/
// pressed states and keyboard activation are the only things
// reimplemented locally, since that's exactly the piece Core doesn't
// offer in this presentation.
Item {
    id: root

    required property NebulaThemeProvider theme
    required property NebulaPowerService powerService
    property bool confirmBeforeAction: false

    // External Tab-chain endpoints — where focus goes after the last
    // visible action (tabTarget) and where Shift+Tab from the first
    // visible action goes (backtabTarget). See Main.qml for wiring.
    property Item tabTarget: null
    property Item backtabTarget: null

    // Exposed so Main.qml can point an external KeyNavigation.tab at the
    // right sub-item — this Item itself is never focusable, only its
    // four children are (same reasoning NebulaPowerButtons already had,
    // just made explicit here since round 6 needs it for real).
    //
    // Gated on `.enabled`, not `.visible`: all four actions are always
    // visible now (see the `enabled:` bindings below and the comment on
    // why) — an unavailable action should still be readable, just
    // dimmed and non-interactive, so it must be skipped in the focus
    // chain instead of hidden.
    readonly property Item firstFocusItem:
        shutdownAction.enabled ? shutdownAction
        : restartAction.enabled ? restartAction
        : sleepAction.enabled ? sleepAction
        : hibernateAction.enabled ? hibernateAction
        : root.tabTarget
    readonly property Item lastFocusItem:
        hibernateAction.enabled ? hibernateAction
        : sleepAction.enabled ? sleepAction
        : restartAction.enabled ? restartAction
        : shutdownAction.enabled ? shutdownAction
        : root.backtabTarget

    // Always visible — see the `enabled:` bindings below.

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: root.theme.spacing.spacingLg

        PowerTextAction {
            id: shutdownAction
            theme: root.theme
            enabled: root.powerService.canShutdown
            label: "Shut Down"
            confirmBeforeAction: root.confirmBeforeAction
            onTriggered: root.powerService.shutdown()
            KeyNavigation.backtab: root.backtabTarget
            KeyNavigation.tab: restartAction.enabled ? restartAction
                : sleepAction.enabled ? sleepAction
                : hibernateAction.enabled ? hibernateAction
                : root.tabTarget
        }

        PowerTextAction {
            id: restartAction
            theme: root.theme
            enabled: root.powerService.canReboot
            label: "Restart"
            confirmBeforeAction: root.confirmBeforeAction
            onTriggered: root.powerService.reboot()
            KeyNavigation.backtab: shutdownAction.enabled ? shutdownAction : root.backtabTarget
            KeyNavigation.tab: sleepAction.enabled ? sleepAction
                : hibernateAction.enabled ? hibernateAction
                : root.tabTarget
        }

        PowerTextAction {
            id: sleepAction
            theme: root.theme
            enabled: root.powerService.canSuspend
            label: "Sleep"
            confirmBeforeAction: root.confirmBeforeAction
            onTriggered: root.powerService.suspend()
            KeyNavigation.backtab: restartAction.enabled ? restartAction
                : shutdownAction.enabled ? shutdownAction
                : root.backtabTarget
            KeyNavigation.tab: hibernateAction.enabled ? hibernateAction : root.tabTarget
        }

        PowerTextAction {
            id: hibernateAction
            theme: root.theme
            enabled: root.powerService.canHibernate
            label: "Hibernate"
            confirmBeforeAction: root.confirmBeforeAction
            onTriggered: root.powerService.hibernate()
            KeyNavigation.backtab: sleepAction.enabled ? sleepAction
                : restartAction.enabled ? restartAction
                : shutdownAction.enabled ? shutdownAction
                : root.backtabTarget
            KeyNavigation.tab: root.tabTarget
        }
    }
}
