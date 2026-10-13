// SPDX-License-Identifier: GPL-2.0-or-later
// "Galaxy features": where Samsung's continuity features live on OneUI OS, as a One UI list card
// (mockup .group / .li / .cat: 26 px card, 34 px coloured circles, inset separators).

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import org.kde.kirigami as Kirigami

import org.kde.plasmasetup.components as PlasmaSetupComponents

PlasmaSetupComponents.SetupModule {
    id: root

    nextEnabled: true

    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // galaxybook-setup.service drops this flag when the speaker driver's key still has to be enrolled
        FolderListModel {
            id: mokFlag
            folder: "file:///run/oneui-os"
            nameFilters: ["mok-pending"]
            showDirs: false
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 30
            Layout.alignment: Qt.AlignHCenter
            visible: mokFlag.count > 0
            type: Kirigami.MessageType.Information
            text: i18n("To turn on the speakers, restart once setup is done. On the blue screen choose <b>Enroll MOK</b>, <b>Continue</b>, <b>Yes</b>, type <b>oneui-os</b>, then <b>Reboot</b>. You only do this once.")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 30
            Layout.alignment: Qt.AlignHCenter
            implicitHeight: list.implicitHeight
            radius: 26
            // mockup --ctl: white 72 % on light, white 8 % on dark
            color: Qt.rgba(1, 1, 1, root.dark ? 0.08 : 0.72)

            ColumnLayout {
                id: list
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 0

                Repeater {
                    // circle colours: the mockup's k-blue / k-indigo / k-violet / k-green
                    model: [
                        { icon: "document-send-symbolic", tint: "#307cee", title: i18n("Quick Share"),
                          text: i18n("Send photos and files to and from nearby Galaxy phones and tablets. Keep Bluetooth on and use the same Wi-Fi.") },
                        { icon: "smartphone-symbolic", tint: "#585ce2", title: i18n("Your phone"),
                          text: i18n("Pair with KDE Connect for notifications, messages, shared clipboard, files and remote control.") },
                        { icon: "audio-headphones-symbolic", tint: "#7560e9", title: i18n("Galaxy Buds"),
                          text: i18n("Battery, noise controls and equalizer in Galaxy Buds Manager.") },
                        { icon: "battery-good-symbolic", tint: "#29aa5a", title: i18n("Battery protection"),
                          text: i18n("Stop charging at 80% in System Settings, Power Management. Fn+F11 switches performance mode.") },
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: Math.max(60, row.implicitHeight + 20)

                        // separator starts after the icon, like One UI lists
                        Rectangle {
                            visible: index > 0
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.leftMargin: 34 + 14
                            anchors.right: parent.right
                            height: 1
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, root.dark ? 0.1 : 0.12)
                        }

                        RowLayout {
                            id: row
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: 14

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 2
                                implicitWidth: 34
                                implicitHeight: 34
                                radius: 17
                                color: modelData.tint
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 17
                                    height: 17
                                    source: modelData.icon
                                    isMask: true
                                    color: "white"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.text
                                    wrapMode: Text.Wrap
                                    opacity: 0.7 // ink-2
                                    lineHeight: 1.2
                                    font: Kirigami.Theme.smallFont
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
