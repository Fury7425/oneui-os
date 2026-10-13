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
            font.pixelSize: Kirigami.Units.gridUnit * 5
            font.weight: Font.Bold
            font.letterSpacing: -Kirigami.Units.gridUnit * 0.1 // -0.02em, like the mockup's display type
            transform: Translate { id: rise }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            // ink-2, not disabledTextColor: secondary text must stay readable (WCAG AA)
            color: Kirigami.Theme.textColor
            opacity: 0.7
            font.pixelSize: Kirigami.Units.gridUnit
            text: i18n("Let's get your laptop ready.")
        }

        Item { Layout.fillHeight: true }

        // One UI greeting: hold, fade out, next word rises in. Kirigami durations follow the global
        // animation speed, so "reduce motion" (speed 0) turns this into a plain swap.
        SequentialAnimation {
            running: root.contentItem.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 1800 }
            NumberAnimation { target: greeting; property: "opacity"; to: 0; duration: Kirigami.Units.shortDuration; easing.type: Easing.InQuad }
            ScriptAction { script: { greeting.index = (greeting.index + 1) % greeting.words.length; rise.y = Kirigami.Units.gridUnit / 2 } }
            ParallelAnimation {
                NumberAnimation { target: greeting; property: "opacity"; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutQuint }
                NumberAnimation { target: rise; property: "y"; to: 0; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutQuint }
            }
        }
    }
}
