// SPDX-License-Identifier: GPL-2.0-or-later
// Galaxy-style first screen: "Hello" cycling through languages, big and bold, before language selection.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.plasmasetup.components as PlasmaSetupComponents

PlasmaSetupComponents.SetupModule {
    id: root

    nextEnabled: true

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Item { Layout.fillHeight: true }

        Label {
            id: greeting

            readonly property var words: ["Hello", "안녕하세요", "Bonjour", "Hola", "こんにちは", "Hallo", "Ciao", "你好", "Olá", "Merhaba"]
            property int index: 0

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: words[index]
            font.pixelSize: Kirigami.Units.gridUnit * 3.5
            font.weight: Font.Bold
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: Kirigami.Theme.disabledTextColor
            text: i18n("Let's get your laptop ready.")
        }

        Item { Layout.fillHeight: true }

        SequentialAnimation {
            running: root.contentItem.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 1800 }
            NumberAnimation { target: greeting; property: "opacity"; to: 0; duration: 250; easing.type: Easing.InCubic }
            ScriptAction { script: greeting.index = (greeting.index + 1) % greeting.words.length }
            NumberAnimation { target: greeting; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
        }
    }
}
