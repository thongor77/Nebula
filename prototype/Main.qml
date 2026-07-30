import QtQuick
import QtQuick.Window

// Nebula Phase 1.0 technical prototype.
// Not a theme, not part of Core: a throwaway probe of the real SDDM/Qt6/
// Wayland environment. See docs/Prototype-Results.md for what it found.
// Deliberately avoids: animations, shaders, Core components, ThemeProvider.

Item {
    id: root
    width: 800
    height: 600

    property string resolutionText: "unknown"
    property string screenCountText: "n/a (no SDDM context — standalone run)"
    property string userText: "n/a (no SDDM context — standalone run)"

    // screenModel is a QAbstractItemModel, not a plain object with a
    // `.count` property — it must be bound as a model (Repeater/ListView)
    // to read its row count. Reading `screenModel.count` directly throws
    // (see docs/Prototype-Results.md for the exact error this produced).
    Repeater {
        id: screenRepeater
        model: (typeof screenModel !== "undefined") ? screenModel : 0
        delegate: Item {}
    }

    Rectangle {
        anchors.fill: parent
        color: "#2E3440"

        Column {
            anchors.centerIn: parent
            spacing: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nebula Prototype"
                color: "#ECEFF4"
                font.pixelSize: 32
                font.bold: true
            }

            Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#88C0D0"
                font.pixelSize: 24

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "hh:mm:ss")
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#D8DEE9"
                font.pixelSize: 16
                text: "Resolution (Screen attached): " + root.resolutionText
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#D8DEE9"
                font.pixelSize: 16
                text: "Screens exposed by SDDM (screenModel.count): " + root.screenCountText
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#D8DEE9"
                font.pixelSize: 16
                text: "Current user (userModel.lastUser): " + root.userText
            }
        }
    }

    // Qt itself has no clean QML-visible "library version" property (only
    // Qt.application.version, which is the *application's* version, not
    // Qt's). The real Qt/module versions are verified from the shell
    // instead (qmake6 --version, pacman -Qi) — see Prototype-Results.md.

    Component.onCompleted: {
        console.log("Nebula prototype diagnostics:")
        console.log("  typeof screenModel =", typeof screenModel)
        console.log("  typeof userModel =", typeof userModel)
        console.log("  typeof sddm =", typeof sddm)
        console.log("  typeof config =", typeof config)
        console.log("  typeof sessionModel =", typeof sessionModel)
        console.log("  typeof keyboard =", typeof keyboard)

        if (typeof Screen !== "undefined") {
            resolutionText = Screen.width + "x" + Screen.height
        }

        // The following context properties only exist when this file is
        // loaded by the real sddm-greeter process, not under plain `qml6`.
        if (typeof screenModel !== "undefined") {
            screenCountText = screenRepeater.count.toString()
        }

        if (typeof userModel !== "undefined" && userModel.lastUser) {
            userText = userModel.lastUser
        }
    }
}
