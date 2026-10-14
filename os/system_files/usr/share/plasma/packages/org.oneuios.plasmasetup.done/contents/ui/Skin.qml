// SPDX-License-Identifier: GPL-2.0-or-later
// Restyles Plasma Setup's own frame to the first boot in the OneUI OS Motion guide ("Power on to desktop"):
//  - the landing becomes the One UI greeting: "Hello" in ten languages on the blurred wallpaper, the language
//    chip and a round arrow button;
//  - the steps sit on one glass card with 34 px corners, the title on the left, and a footer of Back,
//    progress dots and a Next pill ("Start" on the last step).
// Plasma Setup's frame (Wizard.qml, LandingComponent.qml) is compiled into the app, so this looks its items up
// at run time and adjusts them. If an update renames them, nothing is found and the stock frame stays.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: skin

    property Item anchor // any item inside the setup window

    // ---- guide tokens, from the setup window's theme. The probe is created inside the window: a theme object made
    // outside it doesn't follow live colour changes (the look step switches light and dark while you watch). ----
    property var probe: null
    readonly property color ink: probe ? probe.text : "#18181e"
    readonly property bool dark: probe ? probe.bg.hslLightness < 0.5 : false
    function inkA(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }
    readonly property color ink2: inkA(0.72)
    readonly property color line: dark ? Qt.rgba(1, 1, 1, 0.1) : inkA(0.12)
    readonly property color tint: dark ? Qt.rgba(1, 1, 1, 0.06) : inkA(0.06)
    readonly property color track: dark ? Qt.rgba(1, 1, 1, 0.16) : inkA(0.16)
    function glass(a) { const b = probe ? probe.bg : "#f0f0f3"; return Qt.rgba(b.r, b.g, b.b, a) }
    readonly property color on: probe ? probe.hi : "#18181e"
    readonly property color onFg: probe ? probe.hiText : "#fcfcfc"
    readonly property real speed: Kirigami.Units.longDuration / 200
    function ms(t) { return Math.round(t * speed) }
    readonly property var eExit: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var eMove: [0.33, 0, 0.1, 1, 1, 1]
    readonly property var ePop: [0.34, 1.8, 0.64, 1, 1, 1]

    // ---- Plasma Setup's items, found at run time ----
    property var wizard: null
    property var landing: null
    property var card: null

    function find(item, test, depth) {
        if (!item || depth > 14) return null
        if (test(item)) return item
        for (const c of item.children) {
            const r = find(c, test, depth + 1)
            if (r) return r
        }
        return null
    }
    function kind(o) { return String(o).split("(")[0] }

    // The module is also built once outside the window just to check `available`; wait until we are in it.
    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: if (skin.anchor && skin.anchor.Window.window) { stop(); skin.setup() }
    }

    function setup() {
        const win = anchor.Window.window
        wizard = find(win.contentItem, o => o.showingLanding !== undefined && typeof o.requestNextPage === "function", 0)
        if (!wizard) return
        landing = find(wizard, o => typeof o.returnToLanding === "function", 0)
        const steps = find(wizard, o => o !== wizard && o.translateY !== undefined, 0)
        if (!landing || !steps) return
        probe = Qt.createQmlObject(`import QtQuick; import org.kde.kirigami as Kirigami
            Item { Kirigami.Theme.colorSet: Kirigami.Theme.Window; Kirigami.Theme.inherit: false
                readonly property color text: Kirigami.Theme.textColor; readonly property color bg: Kirigami.Theme.backgroundColor
                readonly property color hi: Kirigami.Theme.highlightColor; readonly property color hiText: Kirigami.Theme.highlightedTextColor }`,
            landing, "skinprobe")

        // landing: our blurred ground and greeting replace the photo, the title, the button and "Powered by"
        for (const c of landing.children) {
            if (c.isLandscape !== undefined) c.visible = false
            else if (kind(c).indexOf("ColumnLayout") >= 0) c.visible = false
        }
        landingButton = find(landing, o => kind(o).indexOf("Button") >= 0 && o.clicked !== undefined, 0)
        ground.parent = landing
        hello.parent = landing
        helloIn()

        // card: 620 px of strong glass (content column 540 px with 40 px margins), 34 px corners, hairline edge
        card = find(steps, o => o !== steps && o.radius !== undefined && o.border !== undefined, 0)
        if (!card) return
        card.color = Qt.binding(() => skin.glass(0.84))
        card.radius = 34
        card.border.width = 1
        card.border.color = Qt.binding(() => skin.line)
        card.width = Qt.binding(() => Math.min(620, steps.width - 48))
        const column = card.children[0]
        let heading = null
        for (const c of column.children) {
            if (typeof c.changeText === "function") {
                heading = c
                // .su-t: 32 px bold, on the left; the last page carries its own title
                c.horizontalAlignment = Text.AlignLeft
                c.font.pixelSize = 32
                c.font.weight = Font.Bold
                c.font.letterSpacing = -0.6
                c.leftPadding = 40
                c.rightPadding = 40
                c.topPadding = 20
                c.visible = Qt.binding(() => !skin.wizard.onFinalPage)
            } else if (kind(c).indexOf("RowLayout") >= 0) {
                c.visible = false // the stock Back / Next / Finish row; ours follows
            }
        }
        footer.parent = column
        // the card fits each step (title + page + footer), within 380..640 px; Plasma Setup animates the change
        card.height = Qt.binding(() => {
            const m = skin.wizard.currentModule, page = m && m.contentItem ? m.contentItem.implicitHeight : 400
            const title = heading && heading.visible ? heading.implicitHeight : 0
            return Math.round(Math.max(380, Math.min(640, steps.height - 96, page + title + footer.implicitHeight + 18 + 22 + 40)))
        })
        // steps slide on the guide's Move curve
        for (const a of wizard.contentData || []) {
            if (a && a.duration === 400 && a.easing !== undefined) {
                a.duration = Qt.binding(() => skin.ms(420))
                a.easing.type = Easing.BezierSpline
                a.easing.bezierCurve = skin.eMove
            }
        }
    }

    // =====================================================================================
    // Landing

    property var landingButton: null

    Image {
        id: ground
        anchors.fill: parent
        z: -1
        fillMode: Image.PreserveAspectCrop
        source: "file:///usr/share/oneui-os/wall-blur-" + (skin.dark ? "dark" : "light") + ".png"
    }

    readonly property var words: ["Hello", "안녕하세요", "Bonjour", "Hola", "こんにちは", "Hallo", "Ciao", "你好", "Olá", "Merhaba"]
    property int wordIndex: 0

    Connections {
        target: skin.wizard
        function onShowingLandingChanged() { if (skin.wizard.showingLanding) skin.helloIn() }
    }

    function helloIn() {
        helloOut.stop()
        hello.opacity = 1
        hello.scale = 1
        hello.visible = true
        for (const r of [riseWord, riseSub, riseChip]) r.start()
        goIn.restart()
        cycle.restart()
    }
    function go() {
        if (!wizard || !wizard.showingLanding) return
        cycle.stop()
        helloOut.restart()
        if (landingButton) landingButton.clicked()
    }

    ParallelAnimation {
        id: helloOut
        NumberAnimation { target: hello; property: "opacity"; to: 0; duration: skin.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: skin.eExit }
        NumberAnimation { target: hello; property: "scale"; to: 0.96; duration: skin.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: skin.eExit }
        onFinished: hello.visible = false
    }

    // "Hello" leaves upwards on the Exit curve, the next word rises in on the row spring
    Timer {
        id: cycle
        interval: 1900
        repeat: true
        onTriggered: wordSwap.restart()
    }
    SequentialAnimation {
        id: wordSwap
        ParallelAnimation {
            NumberAnimation { target: word; property: "opacity"; to: 0; duration: skin.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: skin.eExit }
            NumberAnimation { target: wordShift; property: "y"; to: -18; duration: skin.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: skin.eExit }
        }
        ScriptAction { script: { skin.wordIndex = (skin.wordIndex + 1) % skin.words.length; wordShift.y = 18 } }
        ParallelAnimation {
            NumberAnimation { target: word; property: "opacity"; to: 1; duration: skin.ms(220) }
            NumberAnimation { target: wordShift; property: "y"; to: 0; duration: skin.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
    }

    // arrival from the top: 160 ms + 60 ms per row, fade 180 ms and rise 14 px on the row spring
    component Rise: QtObject {
        id: rise
        property Item target
        property int delay
        readonly property Translate shift: Translate {}
        readonly property Animation anim: SequentialAnimation {
            PauseAnimation { duration: skin.ms(rise.delay) }
            ParallelAnimation {
                NumberAnimation { target: rise.target; property: "opacity"; to: 1; duration: skin.ms(180) }
                NumberAnimation { target: rise.shift; property: "y"; to: 0; duration: skin.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }
        Component.onCompleted: target.transform = [shift]
        function start() {
            if (skin.speed === 0) return
            target.opacity = 0
            shift.y = 14
            anim.restart()
        }
    }
    Rise { id: riseWord; target: wordBox; delay: 160 }
    Rise { id: riseSub; target: sub; delay: 220 }
    Rise { id: riseChip; target: chip; delay: 280 }
    SequentialAnimation {
        id: goIn
        ScriptAction { script: if (skin.speed > 0) { goButton.opacity = 0; goButton.scale = 0.4 } }
        PauseAnimation { duration: skin.ms(480) }
        ParallelAnimation {
            NumberAnimation { target: goButton; property: "opacity"; to: 1; duration: skin.ms(200) }
            NumberAnimation { target: goButton; property: "scale"; to: 1; duration: skin.ms(460); easing.type: Easing.OutBack; easing.overshoot: 2 }
        }
    }

    Item {
        id: hello
        anchors.fill: parent
        z: 10
        visible: false

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Item {
                id: wordBox
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.max(word.implicitWidth, 640)
                implicitHeight: word.implicitHeight
                clip: false
                QQC2.Label {
                    id: word
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: skin.words[skin.wordIndex]
                    color: skin.ink
                    font.pixelSize: 96
                    font.weight: Font.Bold
                    font.letterSpacing: -2.9
                    transform: Translate { id: wordShift }
                }
            }
            QQC2.Label {
                id: sub
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Let's get your laptop ready.")
                color: skin.ink2
                font.pixelSize: 18
            }
            // .su-lang: the current language; the first step changes it
            Rectangle {
                id: chip
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                implicitHeight: 36
                implicitWidth: chipRow.implicitWidth + 28
                radius: 18
                color: chipArea.containsMouse ? skin.glass(0.84) : skin.glass(0.62)
                border.width: 1
                border.color: skin.line
                RowLayout {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 7
                    Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: "oneui-os-ms-language"; isMask: true; color: skin.ink }
                    QQC2.Label {
                        text: {
                            const l = Qt.locale()
                            return l.nativeTerritoryName ? l.nativeLanguageName + " (" + l.nativeTerritoryName + ")" : l.nativeLanguageName
                        }
                        color: skin.ink
                        font.pixelSize: 13
                    }
                }
                MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: skin.go() }
            }
            // .su-go: 72 px On circle
            Item {
                id: goButton
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 28
                implicitWidth: 72
                implicitHeight: 72
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: i18n("Start setup")
                Keys.onReturnPressed: skin.go()
                Keys.onSpacePressed: skin.go()
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: skin.on
                    border.width: goButton.activeFocus ? 2 : 0
                    border.color: skin.ink
                    scale: goArea.pressed ? 0.92 : goArea.containsMouse ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: skin.ms(goArea.pressed ? 90 : 220); easing.type: Easing.BezierSpline; easing.bezierCurve: skin.ePop } }
                    Kirigami.Icon { anchors.centerIn: parent; implicitWidth: 30; implicitHeight: 30; source: "oneui-os-ms-arrow_forward"; isMask: true; color: skin.onFg }
                }
                MouseArea { id: goArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: skin.go() }
            }
        }
    }

    // =====================================================================================
    // Card footer: Back (32 px ghost circle), progress dots, Next pill

    RowLayout {
        id: footer
        visible: !!skin.wizard
        Layout.fillWidth: true
        Layout.leftMargin: 28
        Layout.rightMargin: 24
        Layout.topMargin: 18
        Layout.bottomMargin: 22
        spacing: 12

        Rectangle {
            id: back
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: backArea.containsMouse ? skin.tint : "transparent"
            border.width: back.activeFocus ? 1 : 0
            border.color: skin.ink
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: i18n("Back")
            Keys.onReturnPressed: skin.wizard.requestPreviousPage()
            Keys.onSpacePressed: skin.wizard.requestPreviousPage()
            Behavior on color { ColorAnimation { duration: skin.ms(160) } }
            Kirigami.Icon { anchors.centerIn: parent; implicitWidth: 20; implicitHeight: 20; source: "oneui-os-ms-arrow_back"; isMask: true; color: skin.ink }
            MouseArea { id: backArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: skin.wizard.requestPreviousPage() }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 7
            Row {
                anchors.centerIn: parent
                spacing: 5
                Repeater {
                    model: skin.wizard ? skin.wizard.stepCount : 0
                    delegate: Rectangle {
                        required property int index
                        readonly property bool current: skin.wizard && index === skin.wizard.currentIndex
                        width: current ? 22 : 7
                        height: 7
                        radius: 3.5
                        color: current ? skin.ink : skin.track
                        Behavior on width { NumberAnimation { duration: skin.ms(300); easing.type: Easing.BezierSpline; easing.bezierCurve: skin.ePop } }
                        Behavior on color { ColorAnimation { duration: skin.ms(200) } }
                    }
                }
            }
        }

        Rectangle {
            id: next
            readonly property bool enabledNow: !!skin.wizard && !!skin.wizard.currentModule && skin.wizard.currentModule.nextEnabled
            readonly property bool last: !!skin.wizard && skin.wizard.onFinalPage
            function press() {
                if (!enabledNow) return
                if (last) { skin.wizard.currentModule.nextEnabled = false; skin.wizard.finishFinalPage() }
                else skin.wizard.requestNextPage()
            }
            implicitHeight: 44
            implicitWidth: nextRow.implicitWidth + 38
            radius: 22
            color: skin.on
            opacity: enabledNow ? 1 : 0.4
            border.width: next.activeFocus ? 2 : 0
            border.color: skin.ink
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: nextLabel.text
            Keys.onReturnPressed: press()
            Keys.onSpacePressed: press()
            scale: nextArea.pressed ? 0.95 : 1
            Behavior on scale { NumberAnimation { duration: skin.ms(nextArea.pressed ? 90 : 220); easing.type: Easing.BezierSpline; easing.bezierCurve: skin.ePop } }
            Behavior on opacity { NumberAnimation { duration: skin.ms(160) } }
            RowLayout {
                id: nextRow
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 3
                spacing: 8
                QQC2.Label { id: nextLabel; text: next.last ? i18n("Start") : i18n("Next"); color: skin.onFg; font.pixelSize: 14 }
                Kirigami.Icon { implicitWidth: 20; implicitHeight: 20; source: "oneui-os-ms-arrow_forward"; isMask: true; color: skin.onFg }
            }
            MouseArea { id: nextArea; anchors.fill: parent; enabled: next.enabledNow; cursorShape: Qt.PointingHandCursor; onClicked: next.press() }
        }
    }
}
