// SPDX-License-Identifier: GPL-2.0-or-later
// One UI quick settings (mockup .qp). In the taskbar: the Wi-Fi · volume · battery group (mockup .grp + .batt);
// click it and this panel opens, like One UI's quick panel and Windows 11's quick settings.
// Everything uses Plasma's own backends; no service of our own.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.bluezqt as BluezQt
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.volume as Vol
import org.kde.plasma.private.brightnesscontrolplugin as BC
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Quick settings")
    toolTipSubText: wifiSubtitle

    // ---- tokens (mockup tokens-and-components.css) ----
    readonly property color ink: Kirigami.Theme.textColor
    readonly property color paper: Kirigami.Theme.backgroundColor
    readonly property bool dark: paper.hslLightness < 0.5
    function inkA(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }
    function pt(px) { return px * 0.75 } // the mockup's half-pixel sizes (11.5, 12.5) as point sizes
    readonly property color ink2: inkA(0.72)                              // --ink-2
    readonly property color tint: inkA(0.06)                              // --tint
    readonly property color track: inkA(0.16)                             // --track
    readonly property color ctl: Qt.rgba(1, 1, 1, dark ? 0.08 : 0.72)     // --ctl
    readonly property color onFg: dark ? "#18181e" : "#fcfcfc"            // --on-fg (--on is ink)
    readonly property color fill: dark ? "#eeeef0" : "white"              // --fill
    readonly property color fillFg: "#18181e"                             // --fill-fg
    readonly property string netIcon: {
        const c = nmIcon.connectionIcon
        if (c.indexOf("disconnected") >= 0) return "oneui-os-wifi-off"
        if (c.startsWith("network-wired")) return "oneui-os-ethernet"
        return c.startsWith("network-wireless") ? "oneui-os-wifi" : "oneui-os-wifi-off"
    }
    readonly property string volumeIcon: (!sink || sink.muted) ? "oneui-os-volume-muted" : "oneui-os-volume"

    // ---- run a command, optionally reading its output ----
    P5Support.DataSource {
        id: exec
        engine: "executable"
        property var callbacks: ({})
        onNewData: (source, data) => {
            const cb = callbacks[source]
            delete callbacks[source]
            disconnectSource(source)
            if (cb) cb(data.stdout.trim())
        }
    }
    function run(cmd, cb) {
        if (cb) exec.callbacks[cmd] = cb
        exec.connectSource(cmd)
    }
    function settings(kcm) { run("systemsettings " + kcm); root.expanded = false }

    // ---- Wi-Fi ----
    PlasmaNM.EnabledConnections { id: nm }
    PlasmaNM.Handler { id: nmHandler }
    PlasmaNM.NetworkStatus { id: nmStatus }
    PlasmaNM.ConnectionIcon { id: nmIcon }
    readonly property string wifiSubtitle: {
        if (!nm.wirelessEnabled) return i18n("Off")
        const first = (nmStatus.activeConnections || "").split("\n")[0]
        return first ? first.split(":")[0] : i18n("Not connected")
    }

    // ---- Bluetooth ----
    readonly property bool btAvailable: BluezQt.Manager.adapters.length > 0
    readonly property bool btOn: BluezQt.Manager.bluetoothOperational
    readonly property string btSubtitle: {
        if (!btAvailable) return i18n("Unavailable")
        if (!btOn) return i18n("Off")
        const d = BluezQt.Manager.devices.find(dev => dev.connected)
        return d ? d.name : i18n("On")
    }
    function toggleBluetooth() {
        const enable = !btOn
        BluezQt.Manager.bluetoothBlocked = !enable
        for (const a of BluezQt.Manager.adapters) a.powered = enable
    }

    // ---- Do not disturb ----
    NotificationManager.Settings { id: notif }
    readonly property bool dnd: notif.notificationsInhibitedUntil > new Date()
    function toggleDnd() {
        notif.notificationsInhibitedUntil = dnd ? undefined : new Date(2100, 0, 1)
        if (dnd) notif.revokeApplicationInhibitions()
        notif.save()
    }

    // ---- toggles read from the system when the panel opens ----
    property bool performance: false
    property bool eyeComfort: false
    onExpandedChanged: if (root.expanded) {
        run("busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile",
            out => performance = out.indexOf("performance") >= 0)
        run("kreadconfig6 --file kwinrc --group NightColor --key Active", out => eyeComfort = out === "true")
    }

    // ---- volume, brightness, battery, microphone ----
    readonly property var sink: Vol.PreferredDevice.sink
    BC.ScreenBrightnessControl { id: brightness; isSilent: false }
    P5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }
    readonly property bool hasBattery: !!(power.data.Battery && power.data.Battery["Has Battery"])
    readonly property int batteryPercent: hasBattery ? power.data.Battery["Percent"] : 0
    Instantiator {
        id: mics
        model: Vol.SourceOutputModel {}
        delegate: QtObject {
            required property var model
            readonly property string app: model.Client ? model.Client.name : (model.Name || "")
        }
    }

    // =====================================================================================
    // Taskbar: the status group. Tinted while the panel is open (mockup .grp.on).
    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: group.implicitWidth
        Layout.preferredWidth: group.implicitWidth
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Rectangle {
            id: group
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: row.implicitWidth + 24
            implicitHeight: 40
            radius: 20
            color: root.expanded ? root.tint : compact.containsMouse ? root.inkA(0.04) : "transparent"
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 14
                Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: root.netIcon; isMask: true; color: root.ink }
                Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: root.volumeIcon; isMask: true; color: root.ink }
                // .batt: 24 px pill, ink up to the charge with a hard edge (CSS hard-stop gradient), bold number
                Rectangle {
                    id: batt
                    readonly property real p: root.batteryPercent / 100
                    readonly property color on: root.batteryPercent < 20 ? Kirigami.Theme.negativeTextColor : root.ink
                    visible: root.hasBattery
                    implicitWidth: Math.max(42, battLabel.implicitWidth + 18)
                    implicitHeight: 24
                    radius: 12
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: batt.on }
                        GradientStop { position: batt.p; color: batt.on }
                        GradientStop { position: Math.min(1, batt.p + 0.001); color: root.track }
                        GradientStop { position: 1; color: root.track }
                    }
                    PlasmaComponents.Label {
                        id: battLabel
                        anchors.centerIn: parent
                        text: root.batteryPercent
                        font.pointSize: root.pt(12.5)
                        font.weight: Font.Bold
                        font.features: { "tnum": 1 }
                        color: root.batteryPercent > 55 ? root.onFg : root.ink
                    }
                }
            }
        }
    }

    // =====================================================================================
    // The panel (mockup .qp, 380 px; the popup frame adds the 14 px padding)
    component Circle: Rectangle {
        id: circle
        property string icon
        property bool on: false
        property int size: 48
        property int iconSize: 18
        property bool ghost: false // mockup .c.ghost: no fill until hovered or on
        signal clicked()
        implicitWidth: size
        implicitHeight: size
        radius: size / 2
        color: on ? root.ink : !ghost ? root.ctl : circleArea.containsMouse ? root.tint : "transparent"
        scale: circleArea.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutQuart } }
        Behavior on scale { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad } }
        Kirigami.Icon {
            anchors.centerIn: parent
            implicitWidth: circle.iconSize; implicitHeight: circle.iconSize
            source: circle.icon
            isMask: true
            color: circle.on ? root.onFg : root.ink
        }
        MouseArea { id: circleArea; anchors.fill: parent; hoverEnabled: true; onClicked: circle.clicked() }
    }

    component Tile: ColumnLayout {
        id: tile
        property alias icon: c.icon
        property alias on: c.on
        property string label
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 6
        Circle { id: c; Layout.alignment: Qt.AlignHCenter; onClicked: tile.clicked() }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: tile.label
            font.pixelSize: 11
            color: root.ink2
            lineHeight: 1.1
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
    }

    component Wide: Rectangle {
        id: wide
        property alias icon: wc.icon
        property alias on: wc.on
        property string title
        property string subtitle
        signal toggled()
        signal opened()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 60
        radius: 30
        color: root.tint
        MouseArea { anchors.fill: parent; onClicked: wide.opened() }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 12
            spacing: 10
            Circle { id: wc; size: 50; onClicked: wide.toggled() }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents.Label { text: wide.title; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                PlasmaComponents.Label { text: wide.subtitle; font.pointSize: root.pt(11.5); color: root.ink2; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }
    }

    // mockup .hs: 50 px track, white fill with the icon, drag or click to set
    component Bar: Rectangle {
        id: bar
        property real value: 0 // 0..1
        property string icon
        property bool showMore: false
        signal moved(real value)
        signal more()
        Layout.fillWidth: true
        implicitHeight: 50
        radius: 25
        color: root.tint
        clip: true
        // .hs .f: white fill with a soft drop shadow (0 2px 10px -2px, 18 % black)
        Kirigami.ShadowedRectangle {
            width: Math.max(50, bar.width * bar.value)
            height: parent.height
            radius: 25
            color: root.fill
            shadow.size: 10
            shadow.yOffset: 2
            shadow.color: Qt.rgba(0, 0, 0, 0.18)
            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                x: 18
                implicitWidth: 18; implicitHeight: 18
                source: bar.icon
                isMask: true
                color: root.fillFg
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: bar.showMore ? 44 : 0
            preventStealing: true
            function set(x) { bar.moved(Math.max(0, Math.min(1, x / bar.width))) }
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => set(mouse.x)
        }
        Kirigami.Icon {
            visible: bar.showMore
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 14
            implicitWidth: 18; implicitHeight: 18
            source: "oneui-os-more"
            isMask: true
            color: root.ink2
            MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: bar.more() }
        }
    }

    component Chip: Rectangle {
        id: chip
        property string icon
        property string text
        signal clicked()
        implicitHeight: 44
        implicitWidth: chipRow.implicitWidth + 32
        radius: 22
        color: chipArea.containsMouse ? root.inkA(0.1) : root.tint
        // .qrow .btn: 44 px, 12.5 px label, 15 px icon
        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            Kirigami.Icon { implicitWidth: 15; implicitHeight: 15; source: chip.icon; isMask: true; color: root.ink }
            PlasmaComponents.Label { text: chip.text; font.pointSize: root.pt(12.5) }
        }
        MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; onClicked: chip.clicked() }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: 352
        Layout.minimumWidth: 352
        Layout.maximumWidth: 352
        spacing: 10

        // .qhead: title, then edit (Plasma's edit mode: rearrange the taskbar), power, settings as 32 px ghost circles
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 4
            spacing: 2
            PlasmaComponents.Label { text: i18n("Quick settings"); font.pixelSize: 14; font.weight: Font.Bold; Layout.fillWidth: true }
            Circle { size: 32; iconSize: 15; ghost: true; icon: "oneui-os-edit"
                     onClicked: { root.expanded = false; root.run("qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.editMode true") } }
            Circle { size: 32; iconSize: 15; ghost: true; icon: "oneui-os-power"
                     onClicked: { root.run("qdbus-qt6 org.kde.LogoutPrompt /LogoutPrompt promptAll"); root.expanded = false } }
            Circle { size: 32; iconSize: 15; ghost: true; icon: "oneui-os-settings"; onClicked: root.settings("") }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Wide {
                icon: nm.wirelessEnabled ? "oneui-os-wifi" : "oneui-os-wifi-off"
                on: nm.wirelessEnabled
                title: i18n("Wi-Fi")
                subtitle: root.wifiSubtitle
                onToggled: nmHandler.enableWireless(!nm.wirelessEnabled)
                onOpened: root.settings("kcm_networkmanagement")
            }
            Wide {
                icon: "oneui-os-bluetooth"
                on: root.btOn
                title: i18n("Bluetooth")
                subtitle: root.btSubtitle
                onToggled: if (root.btAvailable) root.toggleBluetooth()
                onOpened: root.settings("kcm_bluetooth")
            }
        }

        // .tgroup: 4 x 2 round toggles, then the 32 x 4 handle
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: grid.implicitHeight + 14 + 10 + 4 + 8
            radius: 30
            color: root.tint
            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                width: 32; height: 4; radius: 2
                color: root.track
            }
            GridLayout {
                id: grid
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; topMargin: 14 }
                columns: 4
                rowSpacing: 10
                columnSpacing: 0
                Tile { icon: "oneui-os-dnd"; label: i18n("Do not disturb"); on: root.dnd; onClicked: root.toggleDnd() }
                Tile { icon: "oneui-os-dark-mode"; label: i18n("Dark mode"); on: root.dark
                       onClicked: root.run("plasma-apply-lookandfeel -a " + (root.dark ? "org.oneuios.light.desktop" : "org.oneuios.dark.desktop")) }
                Tile { icon: "oneui-os-quick-share"; label: i18n("Quick Share")
                       onClicked: { root.run("flatpak run io.github.nozwock.Packet"); root.expanded = false } }
                Tile { icon: "oneui-os-multi-control"; label: i18n("Multi Control")
                       onClicked: { root.run("kdeconnect-app"); root.expanded = false } }
                Tile { icon: "oneui-os-performance"; label: i18n("Performance"); on: root.performance
                       onClicked: { root.performance = !root.performance
                                    root.run("busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s " + (root.performance ? "performance" : "balanced")) } }
                Tile { icon: "oneui-os-eye-comfort"; label: i18n("Eye comfort"); on: root.eyeComfort
                       onClicked: { root.eyeComfort = !root.eyeComfort
                                    root.run("sh -c 'kwriteconfig6 --file kwinrc --group NightColor --key Active " + root.eyeComfort + " && qdbus-qt6 org.kde.KWin /KWin reconfigure'") } }
                Tile { icon: "oneui-os-screen-recorder"; label: i18n("Screen recorder")
                       onClicked: { root.expanded = false; root.run("spectacle --record=region") } }
                Tile { icon: "oneui-os-lock"; label: i18n("Lock")
                       onClicked: { root.expanded = false; root.run("loginctl lock-session") } }
            }
        }

        Repeater {
            model: brightness.isBrightnessAvailable ? brightness.displays : null
            delegate: Bar {
                required property var model
                icon: "oneui-os-sun"
                value: model.maxBrightness > 0 ? model.brightness / model.maxBrightness : 0
                onMoved: v => brightness.setBrightness(model.displayName, Math.round(v * model.maxBrightness))
            }
        }

        Bar {
            visible: !!root.sink
            icon: root.volumeIcon
            value: root.sink ? root.sink.volume / Vol.PulseAudio.NormalVolume : 0
            showMore: true
            onMoved: v => { if (root.sink.muted) root.sink.muted = false; root.sink.volume = Math.round(v * Vol.PulseAudio.NormalVolume) }
            onMore: root.settings("kcm_pulseaudio")
        }

        RowLayout {
            spacing: 10
            Chip { icon: "oneui-os-media-output"; text: i18n("Media output"); onClicked: root.settings("kcm_pulseaudio") }
            Chip { icon: "oneui-os-display"; text: i18n("Displays"); onClicked: root.settings("kcm_kscreen") }
        }

        // .privacy: green dot + who is using the microphone
        Rectangle {
            visible: mics.count > 0
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 18
            color: root.tint
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 8
                Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: Kirigami.Theme.positiveTextColor }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pointSize: root.pt(11.5)
                    color: root.ink2
                    text: mics.count > 0 && mics.objectAt(0) && mics.objectAt(0).app
                          ? i18n("Microphone in use by %1", mics.objectAt(0).app) : i18n("Microphone in use")
                }
            }
        }
    }
}
