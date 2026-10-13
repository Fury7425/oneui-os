// SPDX-License-Identifier: GPL-2.0-or-later
// mockup .clock: date 17 px in ink-2, then "09" over "41" at 124 px light, line-height 0.9, -0.02 em.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    // same time source as Plasma's own clock: ticks on the minute, no per-second timer
    P5Support.DataSource {
        id: time
        engine: "time"
        connectedSources: ["Local"]
        interval: 60000
        intervalAlignment: P5Support.Types.AlignToMinute
    }
    readonly property date now: time.data.Local ? time.data.Local.DateTime : new Date()

    // pinned top-left inside the widget area, like the mockup's column
    fullRepresentation: Item {
        // fixed to the mockup's slot (300 x 280): a taller minimum makes the desktop shove the widget
        // sideways to avoid the weather card below
        Layout.minimumWidth: 280
        Layout.minimumHeight: 260
        Layout.fillWidth: true
        Layout.fillHeight: true

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 0

        PlasmaComponents.Label {
            Layout.leftMargin: 10
            Layout.bottomMargin: 8
            text: Qt.locale().toString(root.now, "dddd, MMMM d")
            font.pixelSize: 17
            opacity: 0.7 // ink-2
        }

        Repeater {
            model: [Qt.formatTime(root.now, "hh"), Qt.formatTime(root.now, "mm")]
            delegate: PlasmaComponents.Label {
                required property string modelData
                Layout.leftMargin: 4
                text: modelData
                font.pixelSize: 124
                font.weight: Font.Light
                font.letterSpacing: -2.5
                font.features: { "tnum": 1 }
                lineHeightMode: Text.FixedHeight
                lineHeight: 112
            }
        }
    }
    }
}
