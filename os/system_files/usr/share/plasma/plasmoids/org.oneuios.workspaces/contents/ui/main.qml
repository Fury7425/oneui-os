// SPDX-License-Identifier: GPL-2.0-or-later
// Guide .ws: 7 px dots, 5 px gap. Empty = track, has windows = ink-3, current = 22 px ink pill.
// The current dot stretches on the Pop curve (300 ms), colours fade linearly (200 ms). Click or scroll switches.
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

    readonly property real speed: Kirigami.Units.longDuration / 200
    readonly property color ink: Kirigami.Theme.textColor
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5

    TaskManager.VirtualDesktopInfo { id: desktops }
    readonly property int current: desktops.desktopIds.indexOf(desktops.currentDesktop)

    // every window, to know which desktops are busy
    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: false
        filterByScreen: false
        filterByActivity: false
        groupMode: TaskManager.TasksModel.GroupDisabled
    }
    property int rev: 0
    Connections {
        target: tasks
        function onRowsInserted() { root.rev++ }
        function onRowsRemoved() { root.rev++ }
        function onDataChanged() { root.rev++ }
        function onModelReset() { root.rev++ }
    }
    function busy(id) {
        rev // re-evaluate when the windows change
        for (let i = 0; i < tasks.count; i++) {
            const idx = tasks.makeModelIndex(i)
            if (tasks.data(idx, TaskManager.AbstractTasksModel.IsLauncher)) continue
            if (tasks.data(idx, TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops)) return true
            const d = tasks.data(idx, TaskManager.AbstractTasksModel.VirtualDesktops)
            if (d && d.indexOf(id) >= 0) return true
        }
        return false
    }

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
                    readonly property bool isBusy: root.busy(desktops.desktopIds[index])

                    anchors.verticalCenter: parent.verticalCenter
                    width: isCurrent ? 22 : 7
                    height: 7
                    radius: 3.5
                    color: isCurrent ? root.ink
                         : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, isBusy ? 0.45 : (root.dark ? 0.2 : 0.16))
                    Accessible.role: Accessible.Button
                    Accessible.name: desktops.desktopNames[index] || i18n("Desktop %1", index + 1)

                    Behavior on width { NumberAnimation { duration: Math.round(300 * root.speed); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.34, 1.8, 0.64, 1, 1, 1] } }
                    Behavior on color { ColorAnimation { duration: Math.round(200 * root.speed) } }

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
