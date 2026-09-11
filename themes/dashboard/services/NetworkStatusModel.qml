import QtQuick

// Dashboard-local, experimental read-only network status model — NOT a
// Nebula Core API (see themes/dashboard/README.md "Experimental network
// status" and Nebula-Dashboard-Grayscale-Network-Implementation-Brief.md
// §3/§10). Reads NetworkManager over the system D-Bus via
// `org.kde.plasma.workspace.dbus` (ships with `plasma-workspace`, not
// part of Nebula's universal Qt6/SDDM-only dependency set).
//
// Never statically imports that plugin — QML has no conditional import,
// and a failed top-level `import` aborts loading the whole file. Every
// D-Bus object is instead built from a string via Qt.createQmlObject()
// inside try/catch, so a machine without plasma-workspace (or any other
// D-Bus failure) degrades to `available: false` instead of breaking
// login (brief §5/§10 — "authentication must remain fully usable").
//
// Status display only: no IP/MAC/gateway/DNS, no scanning, no
// NetworkManager mutation (brief §5).
QtObject {
    id: root

    // False until the NetworkManager root D-Bus object is confirmed
    // reachable — components should hide the whole panel while this
    // (or the more specific ethernetPresent/wifiPresent) is false,
    // rather than show an empty "Network" card.
    readonly property bool available: _nmProps !== null

    readonly property bool ethernetPresent: _ethernetDevice !== null
    readonly property bool ethernetConnected: ethernetPresent && Number(_ethernetDevice.state) === _deviceStateActivated
    readonly property string ethernetInterface: ethernetPresent ? _ethernetDevice.iface : ""

    readonly property bool wifiPresent: _wifiDevice !== null
    readonly property bool wifiConnected: wifiPresent && Number(_wifiDevice.state) === _deviceStateActivated
    readonly property string wifiInterface: wifiPresent ? _wifiDevice.iface : ""
    // Best-effort only (brief §5 — "SSID only if straightforward and
    // reliable"): stays "" if the active access point can't be read,
    // never blocks ethernet/wifi presence/state above.
    property string wifiSsid: ""

    property var _nmProps: null
    property var _ethernetDevice: null
    property var _wifiDevice: null
    property var _deviceProbes: []

    // NetworkManager D-Bus enums (public, stable NM API — not Nebula's).
    readonly property int _deviceTypeEthernet: 1
    readonly property int _deviceTypeWifi: 2
    readonly property int _deviceStateActivated: 100

    Component.onCompleted: _connect()

    function _connect() {
        try {
            var obj = Qt.createQmlObject(
                'import QtQuick; import org.kde.plasma.workspace.dbus as Dbus; ' +
                'Dbus.Properties { busType: Dbus.BusType.System; ' +
                'service: "org.freedesktop.NetworkManager"; ' +
                'path: "/org/freedesktop/NetworkManager"; ' +
                'iface: "org.freedesktop.NetworkManager" }',
                root, "nmRootProbe")
            obj.refreshed.connect(function () { root._onDevicesChanged(obj) })
            root._nmProps = obj
        } catch (e) {
            console.warn("NetworkStatusModel: NetworkManager D-Bus unavailable" +
                          " (org.kde.plasma.workspace.dbus missing or system bus" +
                          " unreachable) — network panel stays hidden:", e)
            root._nmProps = null
        }
    }

    function _onDevicesChanged(nmProbe) {
        var devices = nmProbe.properties.Devices
        if (!devices) return
        for (var i = 0; i < devices.length; i++) {
            var path = devices[i].value !== undefined ? devices[i].value : devices[i]
            root._probeDevice(path)
        }
    }

    function _probeDevice(path) {
        for (var i = 0; i < root._deviceProbes.length; i++) {
            if (root._deviceProbes[i].path === path) return
        }
        try {
            var probe = Qt.createQmlObject(
                'import QtQuick; import org.kde.plasma.workspace.dbus as Dbus; ' +
                'Dbus.Properties { busType: Dbus.BusType.System; ' +
                'service: "org.freedesktop.NetworkManager"; ' +
                'path: "' + path + '"; ' +
                'iface: "org.freedesktop.NetworkManager.Device" }',
                root, "devProbe")
            probe.path = path
            probe.refreshed.connect(function () { root._onDeviceRefreshed(path, probe) })
            root._deviceProbes.push(probe)
        } catch (e) {
            // One unreadable device must not break the rest of the panel.
        }
    }

    function _onDeviceRefreshed(path, probe) {
        var p = probe.properties
        var deviceType = Number(p.DeviceType)
        if (deviceType === root._deviceTypeEthernet) {
            root._ethernetDevice = { path: path, state: p.State, iface: p.Interface }
        } else if (deviceType === root._deviceTypeWifi) {
            root._wifiDevice = { path: path, state: p.State, iface: p.Interface }
            if (Number(p.State) === root._deviceStateActivated) {
                root._probeSsid(path)
            }
        }
    }

    function _probeSsid(devicePath) {
        try {
            var wireless = Qt.createQmlObject(
                'import QtQuick; import org.kde.plasma.workspace.dbus as Dbus; ' +
                'Dbus.Properties { busType: Dbus.BusType.System; ' +
                'service: "org.freedesktop.NetworkManager"; ' +
                'path: "' + devicePath + '"; ' +
                'iface: "org.freedesktop.NetworkManager.Device.Wireless" }',
                root, "wirelessProbe")
            wireless.refreshed.connect(function () {
                var ap = wireless.properties.ActiveAccessPoint
                var apPath = ap && ap.value !== undefined ? ap.value : ap
                if (apPath && apPath !== "/") {
                    root._probeAccessPoint(apPath)
                }
            })
        } catch (e) {
            // SSID is optional — silently skip.
        }
    }

    function _probeAccessPoint(apPath) {
        try {
            var accessPoint = Qt.createQmlObject(
                'import QtQuick; import org.kde.plasma.workspace.dbus as Dbus; ' +
                'Dbus.Properties { busType: Dbus.BusType.System; ' +
                'service: "org.freedesktop.NetworkManager"; ' +
                'path: "' + apPath + '"; ' +
                'iface: "org.freedesktop.NetworkManager.AccessPoint" }',
                root, "apProbe")
            accessPoint.refreshed.connect(function () {
                var raw = accessPoint.properties.Ssid
                if (Array.isArray(raw)) {
                    var bytes = raw.map(function (b) { return b.value !== undefined ? b.value : b })
                    root.wifiSsid = root._bytesToString(bytes)
                }
            })
        } catch (e) {
            // SSID is optional — silently skip.
        }
    }

    function _bytesToString(bytes) {
        var s = ""
        for (var i = 0; i < bytes.length; i++) {
            s += String.fromCharCode(bytes[i])
        }
        return s
    }
}
