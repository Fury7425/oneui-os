// SPDX-License-Identifier: GPL-2.0-or-later
// "Galaxy features": where Samsung's continuity features live on OneUI OS, in One UI-style list cards.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import org.kde.plasmasetup.components as PlasmaSetupComponents

PlasmaSetupComponents.SetupModule {
    id: root

    nextEnabled: true

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
            visible: mokFlag.count > 0
            type: Kirigami.MessageType.Information
            text: i18n("To turn on the speakers, restart once setup is done. On the blue screen choose <b>Enroll MOK</b>, <b>Continue</b>, <b>Yes</b>, type <b>oneui-os</b>, then <b>Reboot</b>. You only do this once.")
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextDelegate {
                icon.name: "document-send"
                text: i18n("Quick Share")
                description: i18n("Send photos and files to and from nearby Galaxy phones and tablets. Keep Bluetooth on and use the same Wi-Fi.")
            }
            FormCard.FormDelegateSeparator {}
            FormCard.FormTextDelegate {
                icon.name: "kdeconnect"
                text: i18n("Your phone")
                description: i18n("Pair with KDE Connect for notifications, messages, shared clipboard, files and remote control.")
            }
            FormCard.FormDelegateSeparator {}
            FormCard.FormTextDelegate {
                icon.name: "audio-headphones"
                text: i18n("Galaxy Buds")
                description: i18n("Battery, noise controls and equalizer in Galaxy Buds Manager.")
            }
            FormCard.FormDelegateSeparator {}
            FormCard.FormTextDelegate {
                icon.name: "battery-good"
                text: i18n("Battery protection")
                description: i18n("Stop charging at 80% in System Settings, Power Management. Fn+F11 switches performance mode.")
            }
        }

        Item { Layout.fillHeight: true }
    }
}
