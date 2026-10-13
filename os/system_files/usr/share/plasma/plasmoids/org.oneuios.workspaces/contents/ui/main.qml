// SPDX-License-Identifier: GPL-2.0-or-later
// mockup .ws: 7 px dots, 5 px gap, empty = track, current = 22 px wide ink pill. Click or scroll switches.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    TaskManager.VirtualDesktopInfo { id: desktops }
    readonly property int current: desktops.desktopIds.indexOf(desktops.currentDesktop)

    // VirtualDesktopInfo has no switch call in QML; KWin's D-Bus does it (1-based)
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }
    function show(i) {
        if (i >= 0 && i < desktops.numberOfDesktops && i !== current)
            exec.connectSource("qdbus-qt6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop " + (i + 1))
    }

    fullRepresentation: MouseArea {
        Layout.minimumWidth: dots.implicitWidth + 12
        Layout.preferredWidth: Layout.minimumWidth
        Layout.fillHeight: true
        onWheel: wheel => root.show(root.current + (wheel.angleDelta.y < 0 ? 1 : -1))

        Row {
            id: dots
            anchors.centerIn: parent
            spacing: 5

            Repeater {
                model: desktops.numberOfDesktops
                delegate: Rectangle {
                    required property int index
                    readonly property bool isCurrent: index === root.current
                    readonly property color ink: Kirigami.Theme.textColor

                    anchors.verticalCenter: parent.verticalCenter
                    width: isCurrent ? 22 : 7
                    height: 7
                    radius: 3.5
                    color: isCurrent ? ink : Qt.rgba(ink.r, ink.g, ink.b, 0.22)

                    Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutQuart } }
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.longDuration } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6 // dots are tiny; give the pointer a 19 px target
                        onClicked: root.show(index)
                    }
                }
            }
        }
    }
}
