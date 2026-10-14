// SPDX-License-Identifier: GPL-2.0-or-later
// "Galaxy features" (guide first boot, step 4): where Samsung's continuity features live on OneUI OS, as a One UI
// list group (.group / .li: 26 px card, Material glyph in ink-2, inset separators).
// ponytail: the guide's rows also carry switches; they stay informational until each feature has a real toggle.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import org.kde.kirigami as Kirigami

import org.kde.plasmasetup.components as PlasmaSetupComponents

PlasmaSetupComponents.SetupModule {
    id: root

    nextEnabled: true

    readonly property color ink: Kirigami.Theme.textColor
    readonly property bool dark: Kirigami.Theme.backgroundColor.hslLightness < 0.5

    contentItem: ColumnLayout {
        ColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: root.cardWidth
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            spacing: 0

            // .su-s
            Label {
                Layout.fillWidth: true
                Layout.bottomMargin: 22
                wrapMode: Text.Wrap
                opacity: 0.72
                font.pixelSize: 14
                text: i18n("Where Samsung's continuity features live on OneUI OS.")
            }

            // galaxybook-setup.service drops this flag when the speaker driver's key still has to be enrolled
            FolderListModel {
                id: mokFlag
                folder: "file:///run/oneui-os"
                nameFilters: ["mok-pending"]
                showDirs: false
            }
            Kirigami.InlineMessage {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                visible: mokFlag.count > 0
                type: Kirigami.MessageType.Information
                text: i18n("To turn on the speakers, restart once setup is done. On the blue screen choose <b>Enroll MOK</b>, <b>Continue</b>, <b>Yes</b>, type <b>oneui-os</b>, then <b>Reboot</b>. You only do this once.")
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: list.implicitHeight
                radius: 26
                color: Qt.rgba(1, 1, 1, root.dark ? 0.08 : 0.72) // --ctl

                ColumnLayout {
                    id: list
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 0

                    Repeater {
                        model: [
                            { icon: "oneui-os-ms-swap_horizontal_circle", title: i18n("Quick Share"),
                              text: i18n("Send photos and files to and from nearby Galaxy phones and tablets. Keep Bluetooth on and use the same Wi-Fi.") },
                            { icon: "oneui-os-ms-smartphone", title: i18n("Your phone"),
                              text: i18n("Pair with KDE Connect for notifications, messages, shared clipboard, files and remote control.") },
                            { icon: "oneui-os-ms-headphones", title: i18n("Galaxy Buds"),
                              text: i18n("Battery, noise controls and equalizer in Galaxy Buds Manager.") },
                            { icon: "oneui-os-ms-battery_full", title: i18n("Battery protection"),
                              text: i18n("Stop charging at 80% in System Settings, Power Management. Fn+F11 switches performance mode.") },
                        ]

                        delegate: Item {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: Math.max(60, row.implicitHeight + 20)

                            // separator starts after the glyph, like One UI lists
                            Rectangle {
                                visible: index > 0
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.leftMargin: 24 + 14
                                anchors.right: parent.right
                                height: 1
                                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, root.dark ? 0.1 : 0.12)
                            }

                            RowLayout {
                                id: row
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                spacing: 14

                                Kirigami.Icon {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 1
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    source: modelData.icon
                                    isMask: true
                                    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.72) // ink-2
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label { Layout.fillWidth: true; text: modelData.title; font.pixelSize: 14 }
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.text
                                        wrapMode: Text.Wrap
                                        opacity: 0.72
                                        lineHeight: 1.15
                                        font.pixelSize: 12
                                    }
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
