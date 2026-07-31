import QtQuick
import "../theme"
import "../services"

// Password entry — the only component allowed to call
// NebulaAuthService.authenticate() (see docs/Login-Architecture.md). Never
// stores the password beyond the current text; never talks to SDDM
// directly. See docs/Core-API.md for the full contract.
Rectangle {
    id: root

    required property NebulaThemeProvider theme
    required property NebulaAuthService authService
    // Which user to authenticate as — set by the theme from
    // NebulaUserService.currentUser (see NebulaUserList), not resolved
    // by this component itself.
    property string username: ""

    property string placeholderText: ""
    // Reflects NebulaAuthService by default (displaying its state, not
    // deciding it — see docs/Login-Architecture.md, common auth state
    // model) — a theme may still override either after binding once.
    property bool hasError: authService.errorMessage.length > 0
    property bool isBusy: authService.authenticating
    property bool showToggleEnabled: true
    // Text fallback, always available — a theme isn't required to
    // provide icons. Overridable for localization (Phase 3.1, see
    // docs/Core-Refinement-Review.md §6 — this text was previously
    // hardcoded and untranslatable).
    property string showLabel: "Show"
    property string hideLabel: "Hide"
    // If either is set, the toggle shows an icon instead of text (Phase
    // 3.1, see docs/Core-Refinement-Review.md §2).
    property url showIcon: ""
    property url hideIcon: ""
    property real iconSize: theme.typography.fontSizeBody

    signal submitted(string password)
    signal cleared()

    function submit() {
        if (root.isBusy || input.text.length === 0) {
            return
        }
        root.submitted(input.text)
        root.authService.authenticate(root.username, input.text)
    }

    function clear() {
        input.text = ""
        root.cleared()
    }

    implicitWidth: 240
    implicitHeight: input.implicitHeight + theme.spacing.spacingMd * 2
    radius: theme.radius.radiusMedium
    color: theme.colors.surfaceColor
    opacity: isBusy ? theme.interaction.opacityDisabled : 1.0

    border.width: input.activeFocus ? theme.interaction.borderWidthFocus : theme.interaction.borderWidthThin
    border.color: hasError ? theme.colors.errorColor
        : (input.activeFocus ? theme.colors.accentColor : theme.colors.textSecondary)

    Behavior on border.color {
        ColorAnimation { duration: root.theme.animation.durationFast }
    }

    // Without this, KeyNavigation.tab targeting this component (a plain
    // Rectangle, not a FocusScope) leaves activeFocus on the Rectangle
    // itself instead of the actual TextInput — tabbing in wouldn't let
    // you type until a separate click (found in the Phase 3.1
    // accessibility review, see Development-Journal.md).
    activeFocusOnTab: true
    onActiveFocusChanged: if (root.activeFocus) input.forceActiveFocus()

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: toggle.visible ? toggle.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.theme.spacing.spacingMd
        anchors.rightMargin: root.theme.spacing.spacingSm

        echoMode: toggle.revealed ? TextInput.Normal : TextInput.Password
        enabled: !root.isBusy
        focus: true
        selectByMouse: true
        color: root.theme.colors.textPrimary
        font.family: root.theme.typography.fontFamilyPrimary
        font.pixelSize: root.theme.typography.fontSizeBody

        Keys.onReturnPressed: root.submit()
        Keys.onEnterPressed: root.submit()

        Text {
            visible: input.text.length === 0
            text: root.placeholderText
            color: root.theme.colors.textSecondary
            font: input.font
        }
    }

    Item {
        id: toggle
        visible: root.showToggleEnabled && input.text.length > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: root.theme.spacing.spacingMd
        width: toggleIcon.visible ? toggleIcon.width : toggleLabel.implicitWidth
        height: toggleIcon.visible ? toggleIcon.height : toggleLabel.implicitHeight

        property bool revealed: false
        readonly property url _icon: revealed ? root.hideIcon : root.showIcon

        Image {
            id: toggleIcon
            source: toggle._icon
            visible: toggle._icon.toString().length > 0
            width: root.iconSize
            height: width
        }

        Text {
            id: toggleLabel
            visible: !toggleIcon.visible
            text: toggle.revealed ? root.hideLabel : root.showLabel
            color: root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamilyPrimary
            font.pixelSize: root.theme.typography.fontSizeBody
        }

        MouseArea {
            anchors.fill: parent
            onClicked: toggle.revealed = !toggle.revealed
        }
    }

    Component.onCompleted: input.forceActiveFocus()
}
