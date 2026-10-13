// SPDX-License-Identifier: GPL-2.0-or-later
// mockup .vr + .live chips: 36 px pills in the left taskbar pill.
//   media: 26 px round cover, title in bold, three EQ bars while playing; click = play/pause
//   rec:   red pill, white mic, mm:ss since an app started recording from the microphone
// Nothing running -> zero width, so the pill shrinks back to ✦ + workspace dots.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.volume as Vol
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property bool hasMedia: !!player && !!player.track
    readonly property bool playing: hasMedia && player.playbackStatus === Mpris.PlaybackStatus.Playing

    // apps recording from a microphone (the same streams Plasma's mic indicator watches)
    Instantiator {
        id: recorders
        model: Vol.SourceOutputModel {}
        delegate: QtObject {}
    }
    readonly property bool recording: recorders.count > 0
    property double recordingSince: 0
    onRecordingChanged: recordingSince = recording ? Date.now() : 0

    readonly property color ink: Kirigami.Theme.textColor
    readonly property color tint: Qt.rgba(ink.r, ink.g, ink.b, 0.06)

    fullRepresentation: RowLayout {
        spacing: 7
        Layout.preferredWidth: (root.hasMedia || root.recording) ? implicitWidth : 0
        Layout.minimumWidth: Layout.preferredWidth
        Layout.fillHeight: true
        visible: root.hasMedia || root.recording

        // .vr: divider between workspaces and live activities
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 5
            implicitWidth: 1.5
            implicitHeight: 24
            radius: 1
            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12)
        }

        // media chip
        Rectangle {
            visible: root.hasMedia
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: 36
            implicitWidth: mediaRow.implicitWidth + 5 + 14
            radius: 18
            color: mediaArea.containsMouse ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.1) : root.tint
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

            RowLayout {
                id: mediaRow
                anchors.verticalCenter: parent.verticalCenter
                x: 5
                spacing: 9

                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    clip: true
                    color: "#d0705f" // mockup .art when the player has no cover
                    Image {
                        anchors.fill: parent
                        source: root.hasMedia ? root.player.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(52, 52)
                        visible: status === Image.Ready
                        layer.enabled: true
                    }
                }
                PlasmaComponents.Label {
                    Layout.maximumWidth: 140
                    text: root.hasMedia ? root.player.track : ""
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
                // .eq: 2.5 px bars, 6/12/8 px, bouncing only while playing
                Row {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Repeater {
                        model: [6, 12, 8]
                        delegate: Rectangle {
                            required property int modelData
                            required property int index
                            anchors.bottom: parent.bottom
                            width: 2.5
                            radius: 1.25
                            color: root.ink
                            height: modelData
                            SequentialAnimation on height {
                                running: root.playing
                                loops: Animation.Infinite
                                NumberAnimation { to: 3 + (index * 4) % 9; duration: 260 + index * 70; easing.type: Easing.InOutSine }
                                NumberAnimation { to: modelData; duration: 260 + index * 70; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                    height: 12
                }
            }
            MouseArea {
                id: mediaArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.playing ? root.player.Pause() : root.player.Play()
            }
        }

        // recording chip
        Rectangle {
            visible: root.recording
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: 36
            implicitWidth: recRow.implicitWidth + 10 + 14
            radius: 18
            color: "#e0453d" // mockup --rec, oklch(0.6 0.21 25)

            RowLayout {
                id: recRow
                anchors.verticalCenter: parent.verticalCenter
                x: 10
                spacing: 7
                Kirigami.Icon {
                    implicitWidth: 15
                    implicitHeight: 15
                    source: "microphone-sensitivity-high-symbolic"
                    isMask: true
                    color: "white"
                }
                PlasmaComponents.Label {
                    id: elapsed
                    color: "white"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                    function update() {
                        const s = Math.floor((Date.now() - root.recordingSince) / 1000)
                        text = String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0")
                    }
                    Timer {
                        running: root.recording
                        repeat: true
                        triggeredOnStart: true
                        interval: 1000
                        onTriggered: elapsed.update()
                    }
                }
            }
        }
    }
}
