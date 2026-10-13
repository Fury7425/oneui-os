// SPDX-License-Identifier: GPL-2.0-or-later
// mockup .logo (34 px ink circle, light glyph) or .c.xs (38 px round button) that runs one command.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    toolTipMainText: Plasmoid.configuration.tooltip

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    fullRepresentation: MouseArea {
        id: area
        readonly property bool filled: Plasmoid.configuration.filled
        readonly property int size: filled ? 34 : 38
        Layout.minimumWidth: size + 4
        Layout.preferredWidth: Layout.minimumWidth
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: if (Plasmoid.configuration.command) exec.connectSource(Plasmoid.configuration.command)

        Rectangle {
            anchors.centerIn: parent
            width: area.size
            height: area.size
            radius: width / 2
            readonly property color ink: Kirigami.Theme.textColor
            color: area.filled ? ink : Qt.rgba(ink.r, ink.g, ink.b, area.containsMouse ? 0.08 : 0)
            // press feedback: a small scale-down, released with a quick spring back
            scale: area.pressed ? 0.94 : 1
            Behavior on scale { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: area.filled ? 14 : 18
                height: width
                source: Plasmoid.configuration.icon
                isMask: true
                color: area.filled ? Kirigami.Theme.backgroundColor : Kirigami.Theme.textColor
            }
        }
    }
}
