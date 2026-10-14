// SPDX-License-Identifier: GPL-2.0-or-later
// mockup .vr + .when: a 1.5 x 24 px divider, then "9:41" (15 px bold) over "Mon 12" (11.5 px ink-2), right-aligned.
// Click opens Plasma's own month view, like the calendar flyout on Windows 11.
// ponytail: no events or time zones; Plasma's Digital Clock still has them if someone wants that.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    // no hover tooltip on the right pill, as in the guide (the pill already shows the date)
    toolTipMainText: ""
    toolTipSubText: ""

    P5Support.DataSource {
        id: time
        engine: "time"
        connectedSources: ["Local"]
        interval: 60000
        intervalAlignment: P5Support.Types.AlignToMinute
    }
    readonly property date now: time.data.Local ? time.data.Local.DateTime : new Date()
    readonly property color ink: Kirigami.Theme.textColor

    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: row.implicitWidth
        Layout.preferredWidth: row.implicitWidth
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14 // .tray gap
            Rectangle {
                implicitWidth: 1.5
                implicitHeight: 24
                radius: 1
                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12) // --line
            }
            ColumnLayout {
                spacing: 0
                Layout.rightMargin: 8 // the pill's right padding is 20, the Plasma Style gives 12
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignRight
                    text: Qt.formatTime(root.now, "H:mm")
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignRight
                    text: Qt.locale().toString(root.now, "ddd d")
                    font.pixelSize: 12
                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, compact.containsMouse || root.expanded ? 1 : 0.72)
                }
            }
        }
    }

    fullRepresentation: PlasmaCalendar.MonthView {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 20
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
        today: root.now
        borderOpacity: 0
        firstDayOfWeek: Qt.locale().firstDayOfWeek
    }
}
