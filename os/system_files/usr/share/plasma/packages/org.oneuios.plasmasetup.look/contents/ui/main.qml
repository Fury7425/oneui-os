// SPDX-License-Identifier: GPL-2.0-or-later
// "Choose a look" (guide first boot, step 3): Light or Dark, then a colour palette: Auto (follows the wallpaper),
// Mono, the wallpaper's colour, Blue, Green, Rose. Both apply as you pick them. Plasma Setup copies this account's
// kdeglobals to the new account, so the choice carries over.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

import org.kde.plasmasetup.components as PlasmaSetupComponents

PlasmaSetupComponents.SetupModule {
    id: root

    nextEnabled: true

    readonly property color ink: Kirigami.Theme.textColor
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5
    readonly property real speed: Kirigami.Units.longDuration / 200
    readonly property var ePop: [0.34, 1.8, 0.64, 1, 1, 1]

    // the guide's palettes: hue, chroma (Mono is near-grey). "On" is L 0.52 in light, 0.84 in dark.
    readonly property var palettes: [
        { id: "auto", name: i18n("Auto"), h: 55, c: 0.11 },
        { id: "mono", name: i18n("Mono"), h: 285, c: 0.012 },
        { id: "w0", name: i18n("Wallpaper colour"), h: 55, c: 0.11 },
        { id: "blue", name: i18n("Blue"), h: 258, c: 0.15 },
        { id: "green", name: i18n("Green"), h: 150, c: 0.13 },
        { id: "rose", name: i18n("Rose"), h: 10, c: 0.15 },
    ]
    property string palette: "mono"
    property bool wantDark: dark

    function oklch(L, C, h) {
        const a = C * Math.cos(h * Math.PI / 180), b = C * Math.sin(h * Math.PI / 180)
        const l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3)
        const m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3)
        const s = Math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3)
        const g = x => { x = Math.max(0, Math.min(1, x)); return x <= 0.0031308 ? 12.92 * x : 1.055 * Math.pow(x, 1 / 2.4) - 0.055 }
        return Qt.rgba(g(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
                       g(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
                       g(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s), 1)
    }
    function hex(c) { return "#" + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("") }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }
    // theme first (it rewrites the colours), then the accent on top of it
    function apply() {
        const p = palettes.find(x => x.id === palette)
        const kw = "kwriteconfig6 --file kdeglobals --group General --key "
        let cmd = "plasma-apply-lookandfeel -a org.oneuios." + (wantDark ? "dark" : "light") + ".desktop"
        if (palette === "mono") {
            cmd += " ; " + kw + "AccentColor --delete ; " + kw + "accentColorFromWallpaper false"
        } else {
            cmd += " ; plasma-apply-colorscheme --accent-color '" + hex(oklch(wantDark ? 0.84 : 0.52, p.c, p.h)) + "'"
            cmd += " ; " + kw + "accentColorFromWallpaper " + (palette === "auto")
        }
        // plasma-apply-colorscheme doesn't tell running apps; this does, so the setup window recolours at once
        cmd += " ; dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0"
        exec.connectSource("sh -c \"" + cmd + "\"")
    }

    contentItem: ColumnLayout {
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: root.cardWidth
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            spacing: 0

            // .su-s
            Label {
                Layout.fillWidth: true
                Layout.bottomMargin: 22
                wrapMode: Text.Wrap
                opacity: 0.72
                font.pixelSize: 14
                text: i18n("Both apply as you pick them. Change them any time in Settings, Wallpaper and style.")
            }

            // .themes: two previews with a radio under each
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Repeater {
                    model: [{ dark: false, name: i18n("Light") }, { dark: true, name: i18n("Dark") }]
                    delegate: ColumnLayout {
                        id: th
                        required property var modelData
                        readonly property bool chosen: root.wantDark === modelData.dark
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 8
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 104
                            radius: 18
                            color: th.modelData.dark ? "#1c1b21" : "#d9d7de"
                            border.width: 1
                            border.color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12)
                            readonly property color pane: th.modelData.dark ? Qt.rgba(0.27, 0.26, 0.3, 0.9) : Qt.rgba(0.98, 0.98, 0.99, 0.9)
                            Rectangle { x: parent.width * 0.08; y: parent.height * 0.12; width: parent.width * 0.54; height: parent.height * 0.6; radius: 8; color: parent.pane }
                            Rectangle { x: parent.width * 0.66; y: parent.height * 0.12; width: parent.width * 0.26; height: parent.height * 0.6; radius: 8; color: parent.pane }
                            Rectangle { x: parent.width * 0.3; y: parent.height * 0.8; width: parent.width * 0.4; height: parent.height * 0.12; radius: height / 2; color: parent.pane }
                        }
                        Label { Layout.alignment: Qt.AlignHCenter; text: th.modelData.name; font.pixelSize: 13 }
                        // .rd: 20 px ring, thickens to the On colour when chosen (Pop)
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: "transparent"
                            border.width: th.chosen ? 6 : 2
                            border.color: th.chosen ? Kirigami.Theme.highlightColor : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.45)
                            Behavior on border.width { NumberAnimation { duration: Math.round(220 * root.speed); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
                        }
                        TapHandler { onTapped: if (!th.chosen) { root.wantDark = th.modelData.dark; root.apply() } }
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: th.modelData.name
                        Accessible.checked: th.chosen
                    }
                }
            }

            // .pals: 44 px swatches; the chosen one gets a 2 px ink ring 5 px out
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 22
                spacing: 12
                Repeater {
                    model: root.palettes
                    delegate: Item {
                        id: pal
                        required property var modelData
                        readonly property bool chosen: root.palette === modelData.id
                        width: 44
                        height: 44
                        scale: palTap.pressed ? 0.92 : palHover.hovered ? 1.08 : 1
                        Behavior on scale { NumberAnimation { duration: Math.round(240 * root.speed); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData.name
                        Accessible.checked: chosen
                        ToolTip.visible: palHover.hovered
                        ToolTip.text: modelData.name
                        ToolTip.delay: 350

                        // conic swatch: top half the palette, then a lighter and a palest quarter
                        Canvas {
                            anchors.fill: parent
                            readonly property var p: pal.modelData
                            onPaint: {
                                const ctx = getContext("2d"), r = width / 2, mono = p.id === "mono"
                                const parts = mono
                                    ? [root.oklch(0.3, 0.01, 285), root.oklch(0.62, 0.01, 285), root.oklch(0.9, 0.005, 285)]
                                    : [root.oklch(0.62, p.c, p.h), root.oklch(0.78, p.c * 0.6, p.h + 25), root.oklch(0.9, p.c * 0.35, p.h - 20)]
                                const arcs = [[Math.PI, 2 * Math.PI], [0, Math.PI / 2], [Math.PI / 2, Math.PI]]
                                ctx.reset()
                                arcs.forEach(([a, b], i) => {
                                    ctx.beginPath(); ctx.moveTo(r, r); ctx.arc(r, r, r, a, b); ctx.closePath()
                                    ctx.fillStyle = parts[i].toString(); ctx.fill()
                                })
                            }
                        }
                        Label {
                            anchors.centerIn: parent
                            visible: pal.modelData.id === "auto"
                            text: "A"
                            color: "white"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -5
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: root.ink
                            visible: pal.chosen
                        }
                        HoverHandler { id: palHover }
                        TapHandler { id: palTap; onTapped: if (!pal.chosen) { root.palette = pal.modelData.id; root.apply() } }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
