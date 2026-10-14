// SPDX-License-Identifier: GPL-2.0-or-later
// One UI 9 quick panel, as specified by the OneUI OS Motion guide (mockup/motion.html, .qp): time header, Wi-Fi and
// Bluetooth in two wells, the tile grid in its own frame with a handle for more tiles, sliders with a button beside
// them, media output, and the privacy row. In the taskbar: the Wi-Fi · volume · battery group (.grp + .batt).
// Glyphs are Material Symbols Rounded, filled (oneui-os-ms-*). Everything uses Plasma's own backends.
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
    // no hover tooltip on the right pill, as in the guide
    toolTipMainText: ""
    toolTipSubText: ""

    // ---- guide tokens (OS tokens, Mono palette). Selection colours carry the palette's "On" role. ----
    readonly property color ink: Kirigami.Theme.textColor
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5
    function inkA(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }
    function white(a) { return Qt.rgba(1, 1, 1, a) }
    function pt(px) { return px * 0.75 } // the guide's half-pixel sizes (11.5, 13.5) as point sizes
    readonly property color ink2: inkA(0.72)
    readonly property color tint: dark ? white(0.06) : inkA(0.06)
    readonly property color track: dark ? white(0.16) : inkA(0.16)
    readonly property color line: dark ? white(0.1) : inkA(0.12)
    readonly property color qwell: dark ? Qt.rgba(0, 0, 0, 0.22) : white(0.5)
    readonly property color qgrid: dark ? white(0.05) : white(0.3)
    readonly property color qoff: dark ? white(0.16) : inkA(0.08)
    readonly property color on: Kirigami.Theme.highlightColor
    readonly property color onFg: Kirigami.Theme.highlightedTextColor
    readonly property color fill: dark ? "#f1f1f3" : "#ffffff"
    readonly property color fill2: dark ? "#c6c6cb" : "#ebebef"
    readonly property color fillFg: "#1b1b20"

    // ---- guide motion: four cubic curves; springs as OutBack tuned by eye. Durations follow Plasma's animation
    // speed (0 when animations are off, which leaves plain swaps). ----
    readonly property real speed: Kirigami.Units.longDuration / 200
    function ms(t) { return Math.round(t * speed) }
    readonly property var eEnter: [0.16, 1, 0.3, 1, 1, 1]
    readonly property var eMove: [0.33, 0, 0.1, 1, 1, 1]
    readonly property var ePop: [0.34, 1.8, 0.64, 1, 1, 1]

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
    function launch(cmd) { run(cmd); root.expanded = false }
    function settings(kcm) { launch("systemsettings " + kcm) }

    P5Support.DataSource {
        id: time
        engine: "time"
        connectedSources: ["Local"]
        interval: 60000
        intervalAlignment: P5Support.Types.AlignToMinute
    }
    readonly property date now: time.data.Local ? time.data.Local.DateTime : new Date()

    // ---- Wi-Fi, airplane mode, hotspot ----
    PlasmaNM.EnabledConnections { id: nm }
    PlasmaNM.Handler { id: nmHandler }
    PlasmaNM.NetworkStatus { id: nmStatus }
    PlasmaNM.ConnectionIcon { id: nmIcon }
    readonly property string wifiSubtitle: {
        if (!nm.wirelessEnabled) return i18n("Off")
        const first = (nmStatus.activeConnections || "").split("\n")[0]
        return first ? first.split(":")[0] : i18n("Not connected")
    }
    readonly property bool airplane: PlasmaNM.Configuration.airplaneModeEnabled
    function toggleAirplane() {
        nmHandler.enableAirplaneMode(!airplane)
        PlasmaNM.Configuration.airplaneModeEnabled = !airplane
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

    // ---- volume, brightness, keyboard light, battery, microphone ----
    readonly property var sink: Vol.PreferredDevice.sink
    BC.ScreenBrightnessControl { id: brightness; isSilent: false }
    BC.KeyboardBrightnessControl { id: kbd; isSilent: false }
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
    // Taskbar: the status group (.grp). Hover = tint, open = track.
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
            color: root.expanded ? root.track : compact.containsMouse ? root.tint : "transparent"
            Behavior on color { ColorAnimation { duration: root.ms(120) } }

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 14
                Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: root.netIcon; isMask: true; color: root.ink
                                opacity: nm.wirelessEnabled ? 1 : 0.32
                                Behavior on opacity { NumberAnimation { duration: root.ms(200) } } }
                Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: root.volumeIcon; isMask: true; color: root.ink }
                // .batt: 24 px pill, On colour up to the charge with a hard edge, bold number
                Rectangle {
                    id: batt
                    readonly property real p: root.batteryPercent / 100
                    readonly property color fillColor: root.batteryPercent < 20 ? Kirigami.Theme.negativeTextColor : root.on
                    visible: root.hasBattery
                    implicitWidth: Math.max(42, battLabel.implicitWidth + 18)
                    implicitHeight: 24
                    radius: 12
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: batt.fillColor }
                        GradientStop { position: batt.p; color: batt.fillColor }
                        GradientStop { position: Math.min(1, batt.p + 0.001); color: root.track }
                        GradientStop { position: 1; color: root.track }
                    }
                    // the number reads in On text over the charge and in ink over the track, split at the edge
                    BattLabel { id: battLabel; anchors.centerIn: parent; color: root.ink }
                    Item {
                        width: batt.width * batt.p
                        height: batt.height
                        clip: true
                        BattLabel { x: battLabel.x; y: battLabel.y; color: root.onFg }
                    }
                }
            }
        }
    }

    // =====================================================================================
    // Building blocks

    component BattLabel: PlasmaComponents.Label {
        text: root.batteryPercent
        font.pointSize: root.pt(12.5)
        font.weight: Font.Bold
        font.features: { "tnum": 1 }
    }

    // .c / .c.fx: round control. The "on" fill grows from the centre (Enter, 260 ms); press squeezes to 90 %.
    component Circle: Item {
        id: c
        property string icon
        property bool on: false
        property int size: 52
        property int glyph: 24
        property color off: root.qoff
        property bool ghost: false // .c.ghost: no fill until hovered
        property bool edge: false  // inset 1 px line, for controls sitting in a well
        property bool available: true
        property string label
        signal clicked()
        implicitWidth: size
        implicitHeight: size
        opacity: available ? 1 : 0.38
        activeFocusOnTab: available
        Accessible.role: Accessible.Button
        Accessible.name: label
        Accessible.checkable: true
        Accessible.checked: on
        Keys.onReturnPressed: if (available) clicked()
        Keys.onSpacePressed: if (available) clicked()
        scale: area.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: root.ms(area.pressed ? 90 : 220); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: c.ghost ? (area.containsMouse ? root.tint : "transparent") : c.off
            border.width: c.edge || c.activeFocus ? 1 : 0
            border.color: c.activeFocus ? root.ink : root.line
            Behavior on color { ColorAnimation { duration: root.ms(160) } }
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.on
            scale: c.on ? 1 : 0
            visible: scale > 0
            Behavior on scale { NumberAnimation { duration: root.ms(260); easing.type: Easing.BezierSpline; easing.bezierCurve: root.eEnter } }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            implicitWidth: c.glyph
            implicitHeight: c.glyph
            source: c.icon
            isMask: true
            color: c.on ? root.onFg : root.ink
            Behavior on color { ColorAnimation { duration: root.ms(160) } }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            enabled: c.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: c.clicked()
        }
    }

    // .tog: 52 px circle over an 11.5 px label
    component Tile: ColumnLayout {
        id: tile
        property alias icon: tc.icon
        property alias on: tc.on
        property alias available: tc.available
        property string label
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: 7
        Circle { id: tc; Layout.alignment: Qt.AlignHCenter; label: tile.label; onClicked: tile.clicked() }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: tile.label
            font.pointSize: root.pt(11.5)
            color: root.ink
            opacity: tc.opacity
            lineHeight: 1.1
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
    }

    // .wide: Wi-Fi / Bluetooth well. The circle toggles; the rest opens its settings page.
    component Well: Rectangle {
        id: well
        property alias icon: wc.icon
        property alias on: wc.on
        property string title
        property string subtitle
        signal toggled()
        signal opened()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 62
        radius: 31
        color: root.qwell
        border.width: 1
        border.color: root.line
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: well.opened() }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 12
            spacing: 10
            Circle { id: wc; size: 50; label: well.title; onClicked: well.toggled() }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                PlasmaComponents.Label { text: well.title; font.pointSize: root.pt(13.5); elide: Text.ElideRight; Layout.fillWidth: true }
                PlasmaComponents.Label { text: well.subtitle; font.pointSize: root.pt(11.5); color: root.ink2; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }
    }

    // .hs: 52 px slider; the fill is white with a soft shadow and carries the glyph. Drag, click or scroll.
    component Slider: Rectangle {
        id: s
        property real value: 0 // 0..1
        property string icon
        property bool available: true
        signal moved(real value)
        readonly property bool dragging: drag.pressed
        Layout.fillWidth: true
        implicitHeight: 52
        radius: 26
        color: root.qoff
        opacity: available ? 1 : 0.38
        transform: Scale {
            origin.x: s.width / 2
            origin.y: s.height / 2
            xScale: s.dragging ? 1.015 : 1
            yScale: s.dragging ? 1.08 : 1
            Behavior on xScale { NumberAnimation { duration: root.ms(220); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
            Behavior on yScale { NumberAnimation { duration: root.ms(220); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
        }
        Kirigami.ShadowedRectangle {
            id: fillBar
            width: Math.max(58, s.width * s.value)
            height: parent.height
            radius: 26
            color: root.fill
            shadow.size: 10
            shadow.yOffset: 2
            shadow.color: Qt.rgba(0, 0, 0, 0.18)
            Behavior on width { enabled: !s.dragging; NumberAnimation { duration: root.ms(260); easing.type: Easing.BezierSpline; easing.bezierCurve: root.eMove } }
            Rectangle {
                anchors.fill: parent
                radius: 26
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.5; color: root.fill }
                    GradientStop { position: 1; color: root.fill2 }
                }
            }
            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                x: 16
                implicitWidth: 22
                implicitHeight: 22
                source: s.icon
                isMask: true
                color: root.fillFg
            }
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            enabled: s.available
            preventStealing: true
            cursorShape: Qt.SizeHorCursor
            function set(x) { s.moved(Math.max(0, Math.min(1, x / s.width))) }
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => set(mouse.x)
            onWheel: wheel => s.moved(Math.max(0, Math.min(1, s.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    // Arrival, bottom row first: 40 ms + 22 ms per row, fade 180 ms and rise 14 px on the row spring.
    component Rise: QtObject {
        id: rise
        property Item target
        property int row // counted from the bottom
        readonly property Translate shift: Translate {}
        readonly property Animation anim: SequentialAnimation {
            PauseAnimation { duration: root.ms(40 + rise.row * 22) }
            ParallelAnimation {
                NumberAnimation { target: rise.target; property: "opacity"; to: 1; duration: root.ms(180) }
                NumberAnimation { target: rise.shift; property: "y"; to: 0; duration: root.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }
        Component.onCompleted: target.transform = [shift]
        function start() {
            if (root.speed === 0) return
            target.opacity = 0
            shift.y = 14
            anim.restart()
        }
    }

    // =====================================================================================
    // The panel: 384 px with the popup frame's 14 px padding
    fullRepresentation: ColumnLayout {
        id: panel
        Layout.preferredWidth: 356
        Layout.minimumWidth: 356
        Layout.maximumWidth: 356
        spacing: 10

        readonly property list<QtObject> rises: [
            Rise { target: head; row: 6 }, Rise { target: wells; row: 5 }, Rise { target: tgroup; row: 4 },
            Rise { target: briRow; row: 3 }, Rise { target: volRow; row: 2 }, Rise { target: outRow; row: 1 },
            Rise { target: privacy; row: 0 }
        ]
        function enter() { for (const r of rises) r.start() }
        Component.onCompleted: if (root.expanded) enter()
        Connections {
            target: root
            function onExpandedChanged() { if (root.expanded) panel.enter() }
        }

        // .qhead: time and date, then edit (rearrange the taskbar), power, settings as 36 px ghost circles
        RowLayout {
            id: head
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.topMargin: 2
            spacing: 8
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignBaseline
                text: Qt.formatTime(root.now, "H:mm")
                font.pixelSize: 26
                font.weight: Font.Bold
                font.letterSpacing: -0.5
                font.features: { "tnum": 1 }
            }
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignBaseline
                Layout.fillWidth: true
                text: Qt.locale().toString(root.now, "ddd, MMMM d")
                font.pixelSize: 13
                color: root.ink2
                elide: Text.ElideRight
            }
            RowLayout {
                spacing: 0
                Circle { size: 36; glyph: 20; ghost: true; icon: "oneui-os-ms-edit"; label: i18n("Edit taskbar")
                         onClicked: root.launch("qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.editMode true") }
                Circle { size: 36; glyph: 20; ghost: true; icon: "oneui-os-ms-power_settings_new"; label: i18n("Power options")
                         onClicked: root.launch("qdbus-qt6 org.kde.LogoutPrompt /LogoutPrompt promptAll") }
                Circle { size: 36; glyph: 20; ghost: true; icon: "oneui-os-ms-settings"; label: i18n("Settings")
                         onClicked: root.settings("") }
            }
        }

        RowLayout {
            id: wells
            Layout.fillWidth: true
            spacing: 10
            Well {
                icon: nm.wirelessEnabled ? "oneui-os-ms-wifi" : "oneui-os-ms-wifi_off"
                on: nm.wirelessEnabled
                title: i18n("Wi-Fi")
                subtitle: root.wifiSubtitle
                onToggled: nmHandler.enableWireless(!nm.wirelessEnabled)
                onOpened: root.settings("kcm_networkmanagement")
            }
            Well {
                icon: "oneui-os-ms-bluetooth"
                on: root.btOn
                title: i18n("Bluetooth")
                subtitle: root.btSubtitle
                onToggled: if (root.btAvailable) root.toggleBluetooth()
                onOpened: root.settings("kcm_bluetooth")
            }
        }

        // .tgroup: 4 x 2 tiles, a row more behind the handle (Move, 380 ms)
        Rectangle {
            id: tgroup
            property bool more: false
            Layout.fillWidth: true
            implicitHeight: tcol.implicitHeight + 16 + 1
            radius: 30
            color: root.qgrid
            border.width: 1
            border.color: root.line

            ColumnLayout {
                id: tcol
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 6; rightMargin: 6; topMargin: 16 }
                spacing: 0

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 12
                    columnSpacing: 0
                    Tile { icon: "oneui-os-ms-airplanemode_active"; label: i18n("Airplane mode"); on: root.airplane; onClicked: root.toggleAirplane() }
                    Tile { icon: "oneui-os-ms-do_not_disturb_on"; label: i18n("Do not disturb"); on: root.dnd; onClicked: root.toggleDnd() }
                    Tile { icon: "oneui-os-ms-swap_horizontal_circle"; label: i18n("Quick Share"); onClicked: root.launch("flatpak run io.github.nozwock.Packet") }
                    Tile { icon: "oneui-os-ms-devices"; label: i18n("Multi Control"); onClicked: root.launch("kdeconnect-app") }
                    Tile { icon: "oneui-os-ms-speed"; label: i18n("Performance"); on: root.performance
                           onClicked: { root.performance = !root.performance
                                        root.run("busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s " + (root.performance ? "performance" : "balanced")) } }
                    Tile { icon: "oneui-os-ms-visibility"; label: i18n("Eye comfort"); on: root.eyeComfort
                           onClicked: { root.eyeComfort = !root.eyeComfort
                                        root.run("sh -c 'kwriteconfig6 --file kwinrc --group NightColor --key Active " + root.eyeComfort + " && qdbus-qt6 org.kde.KWin /KWin reconfigure'") } }
                    Tile { icon: "oneui-os-ms-screen_record"; label: i18n("Screen recorder"); onClicked: root.launch("spectacle --record=region") }
                    Tile { icon: "oneui-os-ms-wifi_tethering"; label: i18n("Hotspot"); on: nmHandler.hotspotActive; available: nmHandler.hotspotSupported
                           onClicked: nmHandler.hotspotActive ? nmHandler.stopHotspot() : nmHandler.createHotspot() }
                }

                // .xrow: grows open on the Move curve
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: tgroup.more ? extra.implicitHeight + 12 : 0
                    clip: true
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: root.ms(380); easing.type: Easing.BezierSpline; easing.bezierCurve: root.eMove } }
                    GridLayout {
                        id: extra
                        y: 12
                        width: parent.width
                        columns: 4
                        columnSpacing: 0
                        opacity: tgroup.more ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: root.ms(200) } }
                        Tile { icon: "oneui-os-ms-keyboard"; label: i18n("Keyboard light"); on: kbd.brightness > 0; available: kbd.isBrightnessAvailable
                               onClicked: kbd.brightness = kbd.brightness > 0 ? 0 : kbd.brightnessMax }
                        Tile { icon: "oneui-os-ms-screenshot_monitor"; label: i18n("Screenshot"); onClicked: root.launch("spectacle --region") }
                        Tile { icon: "oneui-os-ms-lock"; label: i18n("Lock"); onClicked: root.launch("loginctl lock-session") }
                        Item { Layout.fillWidth: true; Layout.preferredWidth: 1 }
                    }
                }

                // .handle: 32 x 4, narrows to 18 when open (Pop)
                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: 7
                    implicitHeight: 14
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: tgroup.more ? i18n("Show fewer tiles") : i18n("Show more tiles")
                    Keys.onReturnPressed: tgroup.more = !tgroup.more
                    Keys.onSpacePressed: tgroup.more = !tgroup.more
                    Rectangle {
                        anchors.centerIn: parent
                        width: tgroup.more ? 18 : 32
                        height: 4
                        radius: 2
                        color: parent.activeFocus ? root.ink : root.track
                        Behavior on width { NumberAnimation { duration: root.ms(300); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
                    }
                    MouseArea {
                        anchors.centerIn: parent
                        width: 64
                        height: parent.height
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tgroup.more = !tgroup.more
                    }
                }
            }
        }

        // .srow: slider + the button beside it (dark mode next to brightness, mute next to volume)
        RowLayout {
            id: briRow
            Layout.fillWidth: true
            spacing: 10
            Slider {
                readonly property var display: brightness.isBrightnessAvailable && brightness.displays ? brightness.displays : null
                icon: "oneui-os-ms-light_mode"
                available: brightness.isBrightnessAvailable
                value: available ? briValue.value : 1
                onMoved: v => briValue.set(v)
                // the first display's brightness, through the same model the battery applet uses
                Instantiator {
                    id: briValue
                    property real value: 1
                    property var setter: null
                    function set(v) { if (setter) setter(v) }
                    model: brightness.isBrightnessAvailable ? brightness.displays : null
                    delegate: QtObject {
                        required property var model
                        required property int index
                        Component.onCompleted: if (index === 0) {
                            briValue.value = Qt.binding(() => model.maxBrightness > 0 ? model.brightness / model.maxBrightness : 0)
                            briValue.setter = v => brightness.setBrightness(model.displayName, Math.round(v * model.maxBrightness))
                        }
                    }
                }
            }
            Circle { icon: "oneui-os-ms-dark_mode"; label: i18n("Dark mode"); on: root.dark
                     onClicked: root.run("plasma-apply-lookandfeel -a " + (root.dark ? "org.oneuios.light.desktop" : "org.oneuios.dark.desktop")) }
        }

        RowLayout {
            id: volRow
            Layout.fillWidth: true
            spacing: 10
            Slider {
                available: !!root.sink
                icon: root.sink && root.sink.muted ? "oneui-os-ms-volume_off" : "oneui-os-ms-volume_up"
                value: root.sink && !root.sink.muted ? Math.min(1, root.sink.volume / Vol.PulseAudio.NormalVolume) : 0
                onMoved: v => { if (root.sink.muted) root.sink.muted = false; root.sink.volume = Math.round(v * Vol.PulseAudio.NormalVolume) }
            }
            Circle { icon: "oneui-os-ms-volume_off"; label: i18n("Mute"); on: !!root.sink && root.sink.muted; available: !!root.sink
                     onClicked: root.sink.muted = !root.sink.muted }
        }

        // .qrow: Media output pill, Smart View, Device care
        RowLayout {
            id: outRow
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 26
                color: root.qwell
                border.width: 1
                border.color: root.line
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.settings("kcm_pulseaudio") }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 14
                    spacing: 10
                    Circle { size: 44; icon: "oneui-os-ms-speaker"; label: i18n("Media output"); onClicked: root.settings("kcm_pulseaudio") }
                    PlasmaComponents.Label { Layout.fillWidth: true; text: i18n("Media output"); font.pixelSize: 13; elide: Text.ElideRight }
                }
            }
            Circle { off: root.qwell; edge: true; icon: "oneui-os-ms-tv"; label: i18n("Smart View"); onClicked: root.settings("kcm_kscreen") }
            Circle { off: root.qwell; edge: true; icon: "oneui-os-ms-data_usage"; label: i18n("Device care"); onClicked: root.launch("plasma-systemmonitor") }
        }

        // .privacy: green dot + who is using the microphone
        Rectangle {
            id: privacy
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
