// SPDX-License-Identifier: GPL-2.0-or-later
// Last page of first boot (guide: "You're all set"), replacing Plasma Setup's "Completed!" page: the OneUI OS mark,
// the person's name and where things live. It also carries Skin.qml, which restyles Plasma Setup's frame. This page
// is built with the others when setup starts and is always shown, so the skin is in place from the first screen.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.plasmasetup
import org.kde.plasmasetup.components as PlasmaSetupComponents

PlasmaSetupComponents.SetupModule {
    id: root

    nextEnabled: true

    readonly property Skin skin: Skin { anchor: root.contentItem }
    readonly property string name: (AccountController.fullName || "").trim()

    // the mark settles in when the page comes up
    function onPageActivated() { arrive.restart() }

    contentItem: ColumnLayout {
        spacing: 0

        Item { Layout.fillHeight: true }

        Kirigami.Icon {
            id: mark
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 20
            implicitWidth: 96
            implicitHeight: 96
            source: "oneui-os-logo"
        }
        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.name ? i18n("You're all set, %1", root.name) : i18n("You're all set")
            font.pixelSize: 32
            font.weight: Font.Bold
            font.letterSpacing: -0.6
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 460
            Layout.topMargin: 8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            opacity: 0.72 // ink-2
            font.pixelSize: 14
            lineHeight: 1.15
            text: i18n("Quick settings, notifications and the calendar live in the right pill. Your apps are behind the grid button.")
                  + (AccountController.hasExistingUsers ? "" : " " + i18n("After Start, sign in with the password you just chose."))
        }

        Item { Layout.fillHeight: true }

        ParallelAnimation {
            id: arrive
            readonly property real speed: Kirigami.Units.longDuration / 200
            NumberAnimation { target: mark; property: "opacity"; from: 0; to: 1; duration: Math.round(240 * arrive.speed) }
            NumberAnimation { target: mark; property: "scale"; from: 0.86; to: 1; duration: Math.round(460 * arrive.speed); easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }
    }
}
