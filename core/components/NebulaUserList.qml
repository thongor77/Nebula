import QtQuick
import "../theme"
import "../services"

// Lists available users and manages selection — never reads SDDM's
// `userModel` directly (see docs/Nebula-Principles.md §4). See
// docs/Core-API.md and docs/Login-Architecture.md for the full contract.
Item {
    id: root

    required property NebulaThemeProvider theme
    required property NebulaUserService userService

    readonly property var model: userService.users
    property int currentIndex: 0
    readonly property var currentUser: (currentIndex >= 0 && currentIndex < model.length)
        ? model[currentIndex] : null

    signal userSelected(var user)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    activeFocusOnTab: true

    function selectIndex(index) {
        if (index < 0 || index >= root.model.length) {
            return
        }
        root.currentIndex = index
        root.userSelected(root.model[index])
    }

    Row {
        id: row
        spacing: root.theme.spacing.spacingLg

        Repeater {
            model: root.model

            Column {
                id: delegate
                spacing: root.theme.spacing.spacingXs

                readonly property bool isCurrent: index === root.currentIndex

                Rectangle {
                    width: avatar.width + root.theme.spacing.spacingXs * 2
                    height: avatar.height + root.theme.spacing.spacingXs * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: root.theme.radius.radiusPill
                    color: "transparent"
                    border.width: delegate.isCurrent ? root.theme.interaction.borderWidthFocus : 0
                    border.color: root.theme.colors.accentColor

                    NebulaAvatar {
                        id: avatar
                        anchors.centerIn: parent
                        theme: root.theme
                        source: modelData.icon ? modelData.icon : ""
                        size: 64
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectIndex(index)
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.displayName
                    color: delegate.isCurrent ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamilyPrimary
                    font.pixelSize: root.theme.typography.fontSizeBody
                }
            }
        }
    }

    Keys.onLeftPressed: root.selectIndex(root.currentIndex - 1)
    Keys.onRightPressed: root.selectIndex(root.currentIndex + 1)
    Keys.onReturnPressed: {
        if (root.currentUser) {
            root.userSelected(root.currentUser)
        }
    }
}
