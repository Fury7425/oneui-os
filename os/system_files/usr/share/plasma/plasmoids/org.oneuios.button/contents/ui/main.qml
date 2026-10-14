// SPDX-License-Identifier: GPL-2.0-or-later
// A taskbar button that runs one command. Two looks from the OneUI OS Motion guide:
//   logo: the icon in full colour as a 34 px circle with a hairline ring (.logo); hover grows to 107 %
//   otherwise: a 38 px ghost circle with an 18 px glyph that tints on hover (.c.xs.ghost)
// Both squeeze to 92 % while pressed and spring back on the Pop curve.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    // tooltips come from the ToolTipArea below, styled like the guide's (a small glass pill, one line)
    toolTipMainText: ""
    toolTipSubText: ""

    readonly property real speed: Kirigami.Units.longDuration / 200
    readonly property var ePop: [0.34, 1.8, 0.64, 1, 1, 1]

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    fullRepresentation: MouseArea {
        id: area
        readonly property bool logo: Plasmoid.configuration.logo
        readonly property int size: logo ? 34 : 38
        readonly property color ink: Kirigami.Theme.textColor
        Layout.minimumWidth: size + 4
        Layout.preferredWidth: Layout.minimumWidth
        Layout.fillHeight: true
        hoverEnabled: true
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Plasmoid.configuration.tooltip
        function run() { if (Plasmoid.configuration.command) exec.connectSource(Plasmoid.configuration.command) }
        onClicked: run()
        Keys.onReturnPressed: run()
        Keys.onSpacePressed: run()

        // the guide shows tooltips on the centre pill's buttons only, not on the logo
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            active: !area.logo && !!Plasmoid.configuration.tooltip
            location: Plasmoid.location
            mainItem: PlasmaComponents.Label { text: Plasmoid.configuration.tooltip; font.pixelSize: 12 }
        }

        Item {
            anchors.centerIn: parent
            width: area.size
            height: area.size
            scale: area.pressed ? 0.92 : area.logo && area.containsMouse ? 1.07 : 1
            Behavior on scale { NumberAnimation { duration: Math.round((area.pressed ? 90 : 220) * root.speed); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: area.logo ? "transparent" : Qt.rgba(area.ink.r, area.ink.g, area.ink.b, area.containsMouse ? 0.06 : 0)
                border.width: area.logo || area.activeFocus ? 1 : 0
                border.color: area.activeFocus ? area.ink : Qt.rgba(area.ink.r, area.ink.g, area.ink.b, 0.12)
                z: 1
                Behavior on color { ColorAnimation { duration: Math.round(160 * root.speed) } }
            }
            Kirigami.Icon {
                anchors.centerIn: parent
                width: area.logo ? parent.width : 18
                height: width
                source: Plasmoid.configuration.icon
                isMask: !area.logo
                color: area.ink
            }
        }
    }
}
