// SPDX-License-Identifier: GPL-2.0-or-later
// The centre pill's apps, as in the OneUI OS Motion guide: a divider, pinned apps, a divider, then running apps that
// aren't pinned. 38 px icons, 8 px apart. Under each: a running dot, 4 px for running and 12 px in ink for the
// focused app, stretching on the Pop curve. Icons lift 2 px on hover and squeeze to 92 % while pressed. An app that
// starts pops its icon in from 40 % on a spring; one that quits fades out on the Exit curve.
// Click: open, focus, or minimise when focused. Middle click: new window. Right click: new window, pin, close.
// ponytail: no drag-to-reorder or window thumbnails; the stock Icons-only Task Manager has them if they're missed.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property real speed: Kirigami.Units.longDuration / 200
    function ms(t) { return Math.round(t * speed) }
    readonly property var ePop: [0.34, 1.8, 0.64, 1, 1, 1]
    readonly property color ink: Kirigami.Theme.textColor
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, dark ? 0.1 : 0.12)

    TaskManager.ActivityInfo { id: activityInfo }
    TaskManager.TasksModel {
        id: tasks
        activity: activityInfo.currentActivity
        filterByActivity: true
        filterByVirtualDesktop: false
        filterByScreen: false
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        sortMode: TaskManager.TasksModel.SortManual
        separateLaunchers: true
        launchInPlace: true
        launcherList: Plasmoid.configuration.launchers
        onLauncherListChanged: Plasmoid.configuration.launchers = launcherList
    }

    component Divider: Rectangle {
        implicitWidth: 1.5
        implicitHeight: 24
        radius: 1
        color: root.line
    }

    fullRepresentation: RowLayout {
        spacing: 8
        Layout.fillHeight: true
        Layout.minimumWidth: implicitWidth
        Layout.preferredWidth: implicitWidth

        Divider { Layout.alignment: Qt.AlignVCenter }

        ListView {
            id: list
            Layout.fillHeight: true
            Layout.preferredWidth: contentWidth
            implicitWidth: contentWidth
            orientation: ListView.Horizontal
            interactive: false
            spacing: 8
            model: tasks

            // The slot takes its width at once and only the icon animates: growing the slot would resize the
            // panel window every frame, which stutters and makes KWin recompute the blur each time.
            add: Transition {
                NumberAnimation { property: "grow"; from: 0.4; to: 1; duration: root.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.ms(180) }
            }
            remove: Transition {
                NumberAnimation { property: "grow"; to: 0.6; duration: root.ms(200); easing.type: Easing.InCubic }
                NumberAnimation { property: "opacity"; to: 0; duration: root.ms(160) }
            }

            delegate: MouseArea {
                id: task
                required property var model
                required property int index
                property real grow: 1
                readonly property var modelIndex: tasks.makeModelIndex(index)
                readonly property bool running: !model.IsLauncher && !model.IsStartup
                readonly property bool pinned: tasks.launcherList.length > 0 && tasks.launcherPosition(model.LauncherUrlWithoutIcon) !== -1
                // the divider between pinned and running apps rides on the first running-only app
                // (pinned apps come first and keep their place while running, so they are the first launcherList.length rows)
                readonly property bool firstUnpinned: index === tasks.launcherList.length && index > 0

                width: (firstUnpinned ? 9.5 : 0) + 38
                height: list.height
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: model.display || ""

                function activate() {
                    if (model.IsActive && running) tasks.requestToggleMinimized(modelIndex)
                    else tasks.requestActivate(modelIndex)
                }
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) tasks.requestNewInstance(modelIndex)
                    else if (mouse.button === Qt.RightButton) menu.openRelative()
                    else activate()
                }
                Keys.onReturnPressed: activate()
                Keys.onSpacePressed: activate()
                Keys.onMenuPressed: menu.openRelative()

                Divider {
                    visible: task.firstUnpinned
                    anchors.verticalCenter: parent.verticalCenter
                }

                PlasmaCore.ToolTipArea {
                    id: tip
                    x: task.firstUnpinned ? 9.5 : 0
                    width: 38
                    height: parent.height
                    location: Plasmoid.location
                    // the guide's tooltip: one 12 px line in a small glass pill (the pill is widgets/tooltip.svg)
                    mainItem: PlasmaComponents.Label {
                        text: (task.model.display || "") + (task.model.IsGroupParent ? " · " + i18np("%1 window", "%1 windows", task.model.ChildCount) : "")
                        font.pixelSize: 12
                    }

                    Kirigami.Icon {
                        id: icon
                        anchors.centerIn: parent
                        width: 38
                        height: 38
                        source: task.model.decoration
                        active: task.containsMouse
                        transform: Translate {
                            y: task.containsMouse && !task.pressed ? -2 : 0
                            Behavior on y { NumberAnimation { duration: root.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
                        }
                        scale: (task.pressed ? 0.92 : 1) * task.grow
                        Behavior on scale { enabled: task.grow === 1; NumberAnimation { duration: root.ms(task.pressed ? 90 : 200); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
                        opacity: task.model.IsStartup ? 0.6 : 1
                    }

                    // running dot, 4 px below the icon
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: icon.y + icon.height + 4
                        height: 3
                        radius: 1.5
                        width: !task.running ? 0 : task.model.IsActive ? 12 : 4
                        color: task.model.IsActive ? root.ink : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.72)
                        Behavior on width { NumberAnimation { duration: root.ms(300); easing.type: Easing.BezierSpline; easing.bezierCurve: root.ePop } }
                        Behavior on color { ColorAnimation { duration: root.ms(200) } }
                    }
                }

                PlasmaExtras.Menu {
                    id: menu
                    visualParent: tip
                    placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup
                    PlasmaExtras.MenuItem {
                        text: i18n("New window")
                        icon: "window-new"
                        visible: task.running
                        onClicked: tasks.requestNewInstance(task.modelIndex)
                    }
                    PlasmaExtras.MenuItem {
                        text: task.pinned ? i18n("Unpin from taskbar") : i18n("Pin to taskbar")
                        icon: task.pinned ? "window-unpin" : "window-pin"
                        onClicked: task.pinned ? tasks.requestRemoveLauncher(task.model.LauncherUrlWithoutIcon)
                                               : tasks.requestAddLauncher(task.model.LauncherUrlWithoutIcon)
                    }
                    PlasmaExtras.MenuItem {
                        text: task.model.IsGroupParent ? i18n("Close all windows") : i18n("Close")
                        icon: "window-close"
                        visible: task.running && task.model.IsClosable !== false
                        onClicked: tasks.requestClose(task.modelIndex)
                    }
                }
            }
        }
    }
}
