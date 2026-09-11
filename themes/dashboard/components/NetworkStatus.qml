import QtQuick
import "../../../core/theme"
import "../services"

// Dashboard-local, experimental — read-only Ethernet/Wi-Fi status card
// for the RIGHT region (brief §7). Status display only: no IP/MAC, no
// scanning, no controls. Uses ●/○ glyphs plus opacity/weight rather than
// bright green/red (brief §6 — network state is not an authentication
// error, it should not compete visually with one).
Column {
    id: card

    required property NebulaThemeProvider theme
    required property NetworkStatusModel model

    // Visibility (whole-card hide when nothing to show, brief §5) is
    // decided by the caller (Main.qml), same convention as
    // sessionSelectorColumn — not duplicated here.

    spacing: theme.spacing.spacingSm

    Text {
        text: "Network"
        color: card.theme.colors.textSecondary
        font.family: card.theme.typography.fontFamilySecondary
        font.pixelSize: card.theme.typography.fontSizeBody * 0.8
        font.letterSpacing: 1
    }

    Column {
        visible: card.model.ethernetPresent
        spacing: 2
        width: parent.width

        Text {
            text: "Ethernet"
            color: card.theme.colors.textSecondary
            font.family: card.theme.typography.fontFamilySecondary
            font.pixelSize: card.theme.typography.fontSizeBody * 0.85
        }

        Row {
            spacing: theme.spacing.spacingSm

            Text {
                text: card.model.ethernetConnected ? "Connected" : "Offline"
                color: card.theme.colors.textPrimary
                opacity: card.model.ethernetConnected ? 1.0 : 0.6
                font.family: card.theme.typography.fontFamilyPrimary
                font.pixelSize: card.theme.typography.fontSizeBody * 0.9
            }

            Text {
                text: card.model.ethernetConnected ? "●" : "○"
                color: card.theme.colors.textPrimary
                opacity: card.model.ethernetConnected ? 0.9 : 0.4
                font.pixelSize: card.theme.typography.fontSizeBody * 0.7
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            visible: card.model.ethernetInterface.length > 0
            text: card.model.ethernetInterface
            color: card.theme.colors.textSecondary
            opacity: 0.7
            font.family: card.theme.typography.fontFamilySecondary
            font.pixelSize: card.theme.typography.fontSizeBody * 0.7
        }
    }

    Column {
        visible: card.model.wifiPresent
        spacing: 2
        width: parent.width

        Text {
            text: "Wi-Fi"
            color: card.theme.colors.textSecondary
            font.family: card.theme.typography.fontFamilySecondary
            font.pixelSize: card.theme.typography.fontSizeBody * 0.85
        }

        Row {
            spacing: theme.spacing.spacingSm

            Text {
                text: card.model.wifiConnected ? "Connected" : "Offline"
                color: card.theme.colors.textPrimary
                opacity: card.model.wifiConnected ? 1.0 : 0.6
                font.family: card.theme.typography.fontFamilyPrimary
                font.pixelSize: card.theme.typography.fontSizeBody * 0.9
            }

            Text {
                text: card.model.wifiConnected ? "●" : "○"
                color: card.theme.colors.textPrimary
                opacity: card.model.wifiConnected ? 0.9 : 0.4
                font.pixelSize: card.theme.typography.fontSizeBody * 0.7
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            visible: card.model.wifiSsid.length > 0
            text: card.model.wifiSsid
            color: card.theme.colors.textSecondary
            opacity: 0.7
            font.family: card.theme.typography.fontFamilySecondary
            font.pixelSize: card.theme.typography.fontSizeBody * 0.7
        }

        Text {
            visible: card.model.wifiSsid.length === 0 && card.model.wifiInterface.length > 0
            text: card.model.wifiInterface
            color: card.theme.colors.textSecondary
            opacity: 0.7
            font.family: card.theme.typography.fontFamilySecondary
            font.pixelSize: card.theme.typography.fontSizeBody * 0.7
        }
    }
}
