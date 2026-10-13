// SPDX-License-Identifier: GPL-2.0-or-later
// mockup .card + .rings: "Batteries" title, up to four 54 px rings (4 px stroke), percent bold, name in ink-2.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    // Battery0 = laptop, BatteryN = peripherals (Bluetooth headsets, mice, phones via KDE Connect...)
    P5Support.DataSource {
        id: pm
        engine: "powermanagement"
        connectedSources: sources.filter(s => /^Battery\d+$/.test(s))
    }

    readonly property var batteries: {
        const list = []
        for (const s of pm.connectedSources) {
            const d = pm.data[s]
            if (d && d["Percent"] !== undefined) {
                list.push({ percent: d["Percent"], name: d["Is Power Supply"] ? i18n("Laptop") : (d["Pretty Name"] || d["Type"]),
                            type: d["Type"] || "", supply: !!d["Is Power Supply"] })
            }
        }
        list.sort((a, b) => b.supply - a.supply)
        return list.slice(0, 4)
    }

    function iconFor(type) {
        switch (type) {
        case "Battery": return "computer-laptop-symbolic"
        case "Phone": return "smartphone-symbolic"
        case "Headset": case "Headphones": return "audio-headphones-symbolic"
        case "Mouse": return "input-mouse-symbolic"
        case "Keyboard": return "input-keyboard-symbolic"
        case "GamingInput": return "input-gaming-symbolic"
        default: return "battery-symbolic"
        }
    }

    fullRepresentation: ColumnLayout {
        spacing: 14
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumHeight: implicitHeight

        PlasmaComponents.Label {
            text: i18n("Batteries")
            font.pixelSize: 13
            opacity: 0.7
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: root.batteries
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 2

                    Item {
                        id: ring
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 6
                        implicitWidth: 54
                        implicitHeight: 54
                        readonly property color ink: Kirigami.Theme.textColor
                        // under 20 %: the mockup's warn red
                        readonly property color arc: modelData.percent < 20 ? Kirigami.Theme.negativeTextColor : ink

                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: Qt.rgba(ring.ink.r, ring.ink.g, ring.ink.b, 0.16)
                                strokeWidth: 4
                                fillColor: "transparent"
                                PathAngleArc { centerX: 27; centerY: 27; radiusX: 25; radiusY: 25; startAngle: 0; sweepAngle: 360 }
                            }
                            ShapePath {
                                strokeColor: ring.arc
                                strokeWidth: 4
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                PathAngleArc { centerX: 27; centerY: 27; radiusX: 25; radiusY: 25; startAngle: -90; sweepAngle: 3.6 * modelData.percent }
                            }
                        }
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.iconFor(modelData.type)
                        }
                    }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: i18nc("battery percent", "%1%", modelData.percent)
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 70
                        text: modelData.name
                        elide: Text.ElideRight
                        font.pixelSize: 11
                        opacity: 0.7
                    }
                }
            }
        }
    }
}
