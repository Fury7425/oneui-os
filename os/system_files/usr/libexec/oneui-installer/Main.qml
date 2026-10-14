// SPDX-License-Identifier: GPL-2.0-or-later
// One UI installer screens, drawn like first boot in the OneUI OS Motion guide ("Installer"): "Hello" on the blurred
// wallpaper, then one glass card with Back, progress dots and a Next pill. Steps: disk (with this laptop drawn at the
// top), review, install (a ring), done. The `installer` object comes from oneui-installer (Python).
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: win
    visible: true
    visibility: Window.FullScreen
    title: "Install One UI"
    color: "black"

    // ---- guide tokens from the session's One UI colours (same mapping as the first-boot Skin.qml) ----
    Item { id: probe; Kirigami.Theme.colorSet: Kirigami.Theme.Window; Kirigami.Theme.inherit: false }
    readonly property color ink: probe.Kirigami.Theme.textColor
    readonly property bool dark: probe.Kirigami.Theme.backgroundColor.hslLightness < 0.5
    function inkA(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }
    readonly property color ink2: inkA(0.72)
    readonly property color ink3: inkA(0.5)
    readonly property color line: dark ? Qt.rgba(1, 1, 1, 0.1) : inkA(0.12)
    readonly property color tint: dark ? Qt.rgba(1, 1, 1, 0.06) : inkA(0.06)
    readonly property color track: dark ? Qt.rgba(1, 1, 1, 0.16) : inkA(0.16)
    readonly property color ctl: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.72)
    function glass(a) { const b = probe.Kirigami.Theme.backgroundColor; return Qt.rgba(b.r, b.g, b.b, a) }
    readonly property color on: probe.Kirigami.Theme.highlightColor
    readonly property color onFg: probe.Kirigami.Theme.highlightedTextColor
    readonly property color warn: probe.Kirigami.Theme.negativeTextColor
    readonly property real speed: Kirigami.Units.longDuration / 200 // 0 with animations off
    function ms(t) { return Math.round(t * speed) }
    readonly property var eExit: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var eMove: [0.33, 0, 0.1, 1, 1, 1]

    // ---- flow state ----
    readonly property var steps: ["disk", "review", "install", "done"]
    property int step: -1 // -1 = Hello
    property string disk: ""
    property bool encrypt: false
    readonly property var diskInfo: {
        for (const d of installer.diskList) if (d.path === disk) return d
        return null
    }
    Component.onCompleted: {
        for (const d of installer.diskList) if (d.ok) { disk = d.path; break }
        helloIn()
    }

    function next() {
        if (step === -1) return enterCard()
        const s = steps[step]
        if (s === "disk" && !(diskInfo && diskInfo.ok)) return
        if (s === "review") { installer.install(disk, encrypt); return swap(1) }
        if (s === "install") { if (installer.state === "failed") installer.install(disk, encrypt); return }
        if (s === "done") return installer.restart()
        swap(1)
    }
    function back() {
        if (step === 0) return leaveCard()
        if (step > 0 && step < 2) swap(-1)
    }

    // ---- ground ----
    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: "file:///usr/share/oneui-os/wall-blur-" + (win.dark ? "dark" : "light") + ".png"
    }

    // =====================================================================================
    // Hello (.su-hello): the word cycles through first boot's ten languages

    readonly property var words: ["Hello", "안녕하세요", "Bonjour", "Hola", "こんにちは", "Hallo", "Ciao", "你好", "Olá", "Merhaba"]
    property int wordIndex: 0

    function helloIn() {
        hello.visible = true
        hello.opacity = 1
        hello.scale = 1
        for (const r of [riseWord, riseSub, riseChip]) r.start()
        goIn.restart()
        cycle.restart()
    }
    function enterCard() {
        cycle.stop()
        helloOut.restart()
        step = 0
        card.visible = true
        cardIn.restart()
    }
    function leaveCard() {
        step = -1
        cardOut.restart()
        helloIn()
    }

    Timer { id: cycle; interval: 1900; repeat: true; onTriggered: wordSwap.restart() }
    SequentialAnimation {
        id: wordSwap
        ParallelAnimation {
            NumberAnimation { target: word; property: "opacity"; to: 0; duration: win.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
            NumberAnimation { target: wordShift; property: "y"; to: -18; duration: win.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
        }
        ScriptAction { script: { win.wordIndex = (win.wordIndex + 1) % win.words.length; wordShift.y = 18 } }
        ParallelAnimation {
            NumberAnimation { target: word; property: "opacity"; to: 1; duration: win.ms(220) }
            NumberAnimation { target: wordShift; property: "y"; to: 0; duration: win.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
    }
    ParallelAnimation {
        id: helloOut
        NumberAnimation { target: hello; property: "opacity"; to: 0; duration: win.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
        NumberAnimation { target: hello; property: "scale"; to: 0.96; duration: win.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
        onFinished: hello.visible = win.step === -1
    }

    // arrival from the top: fade 180 ms and rise 14 px on the row spring, 60 ms apart
    component Rise: QtObject {
        id: rise
        property Item target
        property int delay
        readonly property Translate shift: Translate {}
        readonly property Animation anim: SequentialAnimation {
            PauseAnimation { duration: win.ms(rise.delay) }
            ParallelAnimation {
                NumberAnimation { target: rise.target; property: "opacity"; to: 1; duration: win.ms(180) }
                NumberAnimation { target: rise.shift; property: "y"; to: 0; duration: win.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            }
        }
        Component.onCompleted: target.transform = [shift]
        function start() {
            if (win.speed === 0) return
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
        ScriptAction { script: if (win.speed > 0) { goButton.opacity = 0; goButton.scale = 0.4 } }
        PauseAnimation { duration: win.ms(480) }
        ParallelAnimation {
            NumberAnimation { target: goButton; property: "opacity"; to: 1; duration: win.ms(200) }
            NumberAnimation { target: goButton; property: "scale"; to: 1; duration: win.ms(460); easing.type: Easing.OutBack; easing.overshoot: 2 }
        }
    }

    Item {
        id: hello
        anchors.fill: parent
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            Item {
                id: wordBox
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.max(word.implicitWidth, 640)
                implicitHeight: word.implicitHeight
                QQC2.Label {
                    id: word
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.words[win.wordIndex]
                    color: win.ink
                    font.pixelSize: 96
                    font.weight: Font.Bold
                    font.letterSpacing: -2.9
                    transform: Translate { id: wordShift }
                }
            }
            QQC2.Label {
                id: sub
                Layout.alignment: Qt.AlignHCenter
                text: "Let's install One UI on your " + installer.model + "."
                color: win.ink2
                font.pixelSize: 18
            }
            Rectangle { // .su-lang
                id: chip
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                implicitHeight: 36
                implicitWidth: chipRow.implicitWidth + 28
                radius: 18
                color: win.glass(0.62)
                border.width: 1
                border.color: win.line
                RowLayout {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 7
                    Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: "oneui-os-ms-language"; isMask: true; color: win.ink }
                    QQC2.Label {
                        text: Qt.locale().nativeTerritoryName ? Qt.locale().nativeLanguageName + " (" + Qt.locale().nativeTerritoryName + ")" : Qt.locale().nativeLanguageName
                        color: win.ink
                        font.pixelSize: 13
                    }
                }
            }
            RoundButton { // .su-go
                id: goButton
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 28
                size: 72
                filled: true
                icon: "oneui-os-ms-arrow_forward"
                iconSize: 30
                label: "Start"
                onActivated: win.next()
            }
        }
        // "Try it first": closes the installer and leaves the live desktop; "Install One UI" in the menu reopens it
        Pill {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 26
            text: "Try it first"
            filled: false
            onActivated: installer.quit()
        }
    }

    // =====================================================================================
    // The card (.su-card): 720 px of strong glass, 34 px corners; resizes to each step on the window spring

    ParallelAnimation {
        id: cardIn
        ScriptAction { script: { card.opacity = 0; cardShift.y = 28; card.scale = 0.97; body.opacity = 1; bodyShift.x = 0 } }
        NumberAnimation { target: card; property: "opacity"; to: 1; duration: win.ms(180) }
        NumberAnimation { target: cardShift; property: "y"; to: 0; duration: win.ms(520); easing.type: Easing.OutBack; easing.overshoot: 0.8 }
        NumberAnimation { target: card; property: "scale"; to: 1; duration: win.ms(520); easing.type: Easing.OutBack; easing.overshoot: 0.8 }
    }
    SequentialAnimation {
        id: cardOut
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; to: 0; duration: win.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
            NumberAnimation { target: cardShift; property: "y"; to: 20; duration: win.ms(200); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
        }
        ScriptAction { script: card.visible = win.step >= 0 }
    }

    // step change: the page leaves sideways on the Exit curve, the next one slides in on the row spring
    property int pendingDir: 1
    function swap(dir) {
        pendingDir = dir
        stepSwap.restart()
    }
    SequentialAnimation {
        id: stepSwap
        ParallelAnimation {
            NumberAnimation { target: body; property: "opacity"; to: 0; duration: win.ms(140); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
            NumberAnimation { target: bodyShift; property: "x"; to: -win.pendingDir * 24; duration: win.ms(140); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
        }
        ScriptAction { script: { win.step += win.pendingDir; bodyShift.x = win.pendingDir * 32 } }
        ParallelAnimation {
            NumberAnimation { target: body; property: "opacity"; to: 1; duration: win.ms(180) }
            NumberAnimation { target: bodyShift; property: "x"; to: 0; duration: win.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
    }

    Rectangle {
        id: card
        visible: false
        anchors.centerIn: parent
        width: 720
        height: Math.min(parent.height - 48, column.implicitHeight)
        transform: Translate { id: cardShift }
        radius: 34
        color: win.glass(0.84)
        border.width: 1
        border.color: win.line
        clip: true
        Behavior on height { NumberAnimation { duration: win.ms(520); easing.type: Easing.OutBack; easing.overshoot: 0.6 } }

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 0
            Loader {
                id: body
                Layout.fillWidth: true
                Layout.leftMargin: 40
                Layout.rightMargin: 40
                Layout.topMargin: 36
                transform: Translate { id: bodyShift }
                sourceComponent: win.step < 0 ? null
                    : win.steps[win.step] === "disk" ? diskPage
                    : win.steps[win.step] === "review" ? reviewPage
                    : win.steps[win.step] === "install" ? (installer.state === "failed" ? failedPage : installPage)
                    : donePage
            }
            RowLayout { // .su-foot
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 24
                Layout.topMargin: 18
                Layout.bottomMargin: 22
                spacing: 12
                RoundButton {
                    size: 32
                    icon: "oneui-os-ms-arrow_back"
                    iconSize: 20
                    label: "Back"
                    opacity: win.step >= 0 && win.step < 2 ? 1 : 0
                    enabled: opacity > 0
                    onActivated: win.back()
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 7
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Repeater {
                            model: win.steps.length
                            delegate: Rectangle {
                                required property int index
                                readonly property bool current: index === win.step
                                width: current ? 22 : 7
                                height: 7
                                radius: 3.5
                                color: current ? win.ink : win.track
                                Behavior on width { NumberAnimation { duration: win.ms(300); easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                                Behavior on color { ColorAnimation { duration: win.ms(200) } }
                            }
                        }
                    }
                }
                Pill { // .su-next
                    readonly property string s: win.step >= 0 ? win.steps[win.step] : ""
                    text: s === "review" ? "Install" : s === "done" ? "Restart" : s === "install" && installer.state === "failed" ? "Try again" : "Next"
                    trailingIcon: s === "done" ? "oneui-os-ms-restart_alt" : "oneui-os-ms-arrow_forward"
                    filled: true
                    enabled: s === "disk" ? !!(win.diskInfo && win.diskInfo.ok) : s === "install" ? installer.state === "failed" : true
                    onActivated: win.next()
                }
            }
        }
    }

    // when the install finishes, the card moves on to "ready" by itself
    Connections {
        target: installer
        function onChanged() {
            if (installer.state === "done" && win.steps[win.step] === "install" && !doneDelay.running) doneDelay.start()
        }
    }
    Timer { id: doneDelay; interval: 700; onTriggered: win.swap(1) }

    Shortcut { sequences: ["Return", "Enter"]; onActivated: win.next() }

    // =====================================================================================
    // Pages

    component Title: QQC2.Label { // .su-t
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        color: win.ink
        font.pixelSize: 32
        font.weight: Font.Bold
        font.letterSpacing: -0.6
        wrapMode: Text.WordWrap
    }
    component Sub: QQC2.Label { // .su-s
        Layout.fillWidth: true
        Layout.bottomMargin: 22
        color: win.ink2
        font.pixelSize: 14
        lineHeight: 1.3
        wrapMode: Text.WordWrap
    }
    component Group: Rectangle { // .group: one tinted block, rows inside with hairlines
        default property alias rows: rowsCol.data
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        implicitHeight: rowsCol.implicitHeight
        radius: 26
        color: win.ctl
        ColumnLayout { id: rowsCol; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 0 }
    }
    component Row_: Item { // .li
        id: li
        property string icon
        property string title
        property string detail
        property bool first: true
        property alias trailing: trail.data
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: Math.max(60, rowLayout.implicitHeight + 20)
        Rectangle { visible: !li.first; anchors.top: parent.top; anchors.left: parent.left; anchors.leftMargin: 36; anchors.right: parent.right; height: 1; color: win.line }
        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: 14
            Kirigami.Icon { implicitWidth: 22; implicitHeight: 22; source: li.icon; isMask: true; color: win.ink2 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                QQC2.Label { Layout.fillWidth: true; text: li.title; color: win.ink; font.pixelSize: 13.5; elide: Text.ElideRight }
                QQC2.Label { Layout.fillWidth: true; visible: text !== ""; text: li.detail; color: win.ink2; font.pixelSize: 11.5; wrapMode: Text.WordWrap }
            }
            Item { id: trail; implicitWidth: childrenRect.width; implicitHeight: childrenRect.height }
        }
        MouseArea { anchors.fill: parent; z: -1; onClicked: li.clicked() }
    }

    Component {
        id: diskPage
        ColumnLayout {
            spacing: 0
            // this laptop: a line drawing with the One UI wallpaper on its screen, the model read from the firmware
            RowLayout {
                Layout.bottomMargin: 26
                spacing: 20
                Item {
                    implicitWidth: 150
                    implicitHeight: 100
                    Rectangle {
                        id: lid
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: 126
                        height: 84
                        radius: 9
                        color: "#16151b"
                        Image {
                            anchors.fill: parent
                            anchors.margins: 5
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 256
                            source: "file:///usr/share/wallpapers/OneUIOS/contents/" + (win.dark ? "images_dark" : "images") + "/2880x1800.png"
                        }
                    }
                    Rectangle { // deck, with the opening notch
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: lid.height + 1
                        width: 150
                        height: 8
                        radius: 4
                        color: win.dark ? "#4a4952" : "#c6c5cd"
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 26; height: 3; radius: 1.5; color: win.dark ? "#34333a" : "#a9a8b1" }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    QQC2.Label { text: installer.model; color: win.ink; font.pixelSize: 20; font.weight: Font.Bold }
                    QQC2.Label { Layout.fillWidth: true; text: installer.specs; color: win.ink2; font.pixelSize: 12.5; wrapMode: Text.WordWrap }
                }
            }
            Title { text: "Where should One UI go?" }
            Sub { text: "Pick the disk to install on. Everything on it is erased." }
            Group {
                Repeater {
                    model: installer.diskList
                    delegate: Row_ {
                        required property var modelData
                        required property int index
                        first: index === 0
                        icon: modelData.usb ? "oneui-os-ms-usb" : "oneui-os-ms-hard_drive"
                        title: modelData.title
                        detail: modelData.detail
                        opacity: modelData.ok ? 1 : 0.45
                        onClicked: if (modelData.ok) win.disk = modelData.path
                        trailing: Rectangle { // radio
                            width: 22; height: 22; radius: 11
                            color: "transparent"
                            border.width: 2
                            border.color: win.disk === modelData.path ? win.on : win.ink3
                            Rectangle {
                                anchors.centerIn: parent
                                width: 10; height: 10; radius: 5
                                color: win.on
                                scale: win.disk === modelData.path ? 1 : 0
                                Behavior on scale { NumberAnimation { duration: win.ms(260); easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.leftMargin: 4
                Layout.topMargin: 2
                Layout.bottomMargin: 16
                spacing: 8
                visible: !!win.diskInfo
                Kirigami.Icon { implicitWidth: 18; implicitHeight: 18; source: "oneui-os-ms-warning"; isMask: true; color: win.warn }
                QQC2.Label {
                    text: win.diskInfo && win.diskInfo.windows ? "Windows on this disk will be erased. Back up anything you need first." : "Everything on this disk will be erased."
                    color: win.warn
                    font.pixelSize: 12.5
                }
            }
            Group {
                Row_ {
                    icon: "oneui-os-ms-lock"
                    title: "Encrypt the disk"
                    detail: installer.hasTpm ? "Unlocks with this laptop's security chip (TPM) when it starts." : "This laptop has no TPM security chip."
                    opacity: installer.hasTpm ? 1 : 0.45
                    onClicked: if (installer.hasTpm) win.encrypt = !win.encrypt
                    trailing: Switch_ { on: win.encrypt && installer.hasTpm }
                }
            }
        }
    }

    Component {
        id: reviewPage
        ColumnLayout {
            spacing: 0
            Title { text: "Ready to install" }
            Sub { text: "One UI erases the disk below and installs on it. It takes about ten minutes; keep the laptop plugged in." }
            Group {
                Row_ { icon: win.diskInfo && win.diskInfo.usb ? "oneui-os-ms-usb" : "oneui-os-ms-hard_drive"; title: win.diskInfo ? win.diskInfo.title : ""; detail: "Erased, then One UI" }
                Row_ { first: false; icon: "oneui-os-ms-lock"; title: win.encrypt ? "Encrypted" : "Not encrypted"; detail: win.encrypt ? "Unlocks with this laptop's TPM" : "You can't turn this on later without reinstalling" }
                Row_ { first: false; icon: "oneui-os-ms-language"; title: "Language, Wi-Fi and your account"; detail: "Set up after the restart" }
            }
        }
    }

    Component {
        id: installPage
        ColumnLayout {
            spacing: 0
            Title { text: "Installing One UI" }
            Sub { text: "Keep the laptop plugged in. It restarts into One UI when you're ready." }
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 18
                spacing: 6
                Ring { Layout.alignment: Qt.AlignHCenter }
                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: installer.progress < 0.06 ? "Preparing the disk"
                        : installer.progress < 0.82 ? "Copying One UI"
                        : installer.progress < 0.9 ? "Setting up One UI"
                        : installer.progress < 1 ? "Installing the boot loader" : "Finishing up"
                    color: win.ink2
                    font.pixelSize: 14
                }
            }
            QQC2.Label { Layout.leftMargin: 4; Layout.bottomMargin: 8; text: "WHILE YOU WAIT"; color: win.ink3; font.pixelSize: 11; font.letterSpacing: 0.7 }
            Group {
                id: tipGroup
                readonly property var tips: [
                    ["oneui-os-ms-swap_horizontal_circle", "Quick Share", "Send photos and files from your Galaxy phone to this laptop with a tap."],
                    ["oneui-os-ms-smartphone", "Your phone", "Pair your Galaxy phone for notifications, messages and a shared clipboard."],
                    ["oneui-os-ms-battery_full", "Battery protection", "Stop charging at 80% to keep the battery healthy for longer."],
                    ["oneui-os-ms-speed", "Performance mode", "Fn + F11 switches between quiet, balanced and performance."]
                ]
                property int tip: 0
                Row_ {
                    id: tipRow
                    icon: tipGroup.tips[tipGroup.tip][0]
                    title: tipGroup.tips[tipGroup.tip][1]
                    detail: tipGroup.tips[tipGroup.tip][2]
                    transform: Translate { id: tipShift }
                }
                Timer {
                    interval: 3600; repeat: true; running: true
                    onTriggered: tipSwap.restart()
                }
                SequentialAnimation {
                    id: tipSwap
                    ParallelAnimation {
                        NumberAnimation { target: tipRow; property: "opacity"; to: 0; duration: win.ms(140); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
                        NumberAnimation { target: tipShift; property: "x"; to: -24; duration: win.ms(140); easing.type: Easing.BezierSpline; easing.bezierCurve: win.eExit }
                    }
                    ScriptAction { script: { tipGroup.tip = (tipGroup.tip + 1) % tipGroup.tips.length; tipShift.x = 32 } }
                    ParallelAnimation {
                        NumberAnimation { target: tipRow; property: "opacity"; to: 1; duration: win.ms(180) }
                        NumberAnimation { target: tipShift; property: "x"; to: 0; duration: win.ms(420); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                    }
                }
            }
        }
    }

    Component {
        id: failedPage
        ColumnLayout {
            spacing: 0
            Title { text: "One UI couldn't install" }
            Sub { text: "The disk was erased, but One UI isn't on it yet. Try again, or restart and take out the USB drive to stop." }
            Group {
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    text: installer.log || "No details."
                    color: win.ink2
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 12
                }
            }
        }
    }

    Component {
        id: donePage
        ColumnLayout {
            spacing: 0
            Kirigami.Icon {
                id: mark
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 20
                implicitWidth: 96
                implicitHeight: 96
                source: "oneui-os-logo"
                // the mark arrives on the panel spring, like first boot's last page
                scale: 0.86
                opacity: 0
                Component.onCompleted: markIn.start()
                ParallelAnimation {
                    id: markIn
                    NumberAnimation { target: mark; property: "opacity"; to: 1; duration: win.ms(240) }
                    NumberAnimation { target: mark; property: "scale"; to: 1; duration: win.ms(480); easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }
            }
            Title { text: "Your " + installer.model + " is ready"; horizontalAlignment: Text.AlignHCenter }
            Sub { text: "Take out the USB drive, then restart. First boot sets up Wi-Fi, your account and the look."; horizontalAlignment: Text.AlignHCenter }
        }
    }

    // =====================================================================================
    // Controls

    // the install ring: 16% track, ink arc with round caps, the number inside. A quarter arc spins until the first
    // step lands; after that it eases toward each new value (12% of the gap per frame) instead of jumping.
    component Ring: Item {
        id: ring
        implicitWidth: 220
        implicitHeight: 220
        property real shown: 0
        property real spin: 0
        FrameAnimation {
            running: ring.visible
            onTriggered: {
                const t = installer.progress
                ring.shown = win.speed === 0 || Math.abs(t - ring.shown) < 0.0005 ? t : ring.shown + (t - ring.shown) * 0.12
                if (ring.shown <= 0.0005 && win.speed > 0) ring.spin = (ring.spin + 5.2) % 360
            }
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "transparent"
                strokeColor: win.track
                strokeWidth: 12
                PathAngleArc { centerX: 110; centerY: 110; radiusX: 100; radiusY: 100; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: win.on
                strokeWidth: 12
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 110; centerY: 110; radiusX: 100; radiusY: 100
                    startAngle: ring.shown <= 0.0005 ? ring.spin - 90 : -90
                    sweepAngle: ring.shown <= 0.0005 ? 90 : 360 * Math.min(ring.shown, 1)
                }
            }
        }
        RowLayout {
            anchors.centerIn: parent
            visible: ring.shown > 0.0005
            spacing: 2
            QQC2.Label { Layout.alignment: Qt.AlignBaseline; text: Math.round(ring.shown * 100); color: win.ink; font.pixelSize: 64; font.weight: Font.Bold; font.letterSpacing: -1.9; font.features: { "tnum": 1 } }
            QQC2.Label { Layout.alignment: Qt.AlignBaseline; text: "%"; color: win.ink2; font.pixelSize: 24; font.weight: Font.Bold }
        }
        Accessible.role: Accessible.ProgressBar
        Accessible.name: "Installing, " + Math.round(installer.progress * 100) + "%"
    }

    component Switch_: Rectangle {
        property bool on: false
        implicitWidth: 44
        implicitHeight: 26
        radius: 13
        color: on ? win.on : (win.dark ? Qt.rgba(1, 1, 1, 0.18) : win.inkA(0.2))
        Behavior on color { ColorAnimation { duration: win.ms(200) } }
        Rectangle {
            y: 3
            x: parent.on ? 21 : 3
            width: 20; height: 20; radius: 10
            color: "white"
            Behavior on x { NumberAnimation { duration: win.ms(260); easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
        }
    }

    component RoundButton: Item {
        id: rb
        property int size: 56
        property bool filled: false
        property string icon
        property int iconSize: 22
        property string label
        signal activated()
        implicitWidth: size
        implicitHeight: size
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: label
        Keys.onSpacePressed: activated()
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: rb.filled ? win.on : (area.containsMouse ? win.tint : "transparent")
            border.width: rb.activeFocus ? 2 : 0
            border.color: win.ink
            scale: area.pressed ? 0.92 : area.containsMouse && rb.filled ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: win.ms(area.pressed ? 90 : 220); easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
            Behavior on color { ColorAnimation { duration: win.ms(160) } }
            Kirigami.Icon { anchors.centerIn: parent; implicitWidth: rb.iconSize; implicitHeight: rb.iconSize; source: rb.icon; isMask: true; color: rb.filled ? win.onFg : win.ink }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rb.activated() }
    }

    component Pill: Rectangle {
        id: pill
        property string text
        property string trailingIcon
        property bool filled: true
        signal activated()
        implicitHeight: 44
        implicitWidth: pillRow.implicitWidth + (trailingIcon ? 38 : 44)
        radius: 22
        color: filled ? win.on : (pillArea.containsMouse ? win.glass(0.84) : win.glass(0.62))
        border.width: filled ? (activeFocus ? 2 : 0) : 1
        border.color: filled ? win.ink : win.line
        opacity: enabled ? 1 : 0.4
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: text
        Keys.onSpacePressed: if (enabled) activated()
        scale: pillArea.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: win.ms(pillArea.pressed ? 90 : 220); easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
        Behavior on opacity { NumberAnimation { duration: win.ms(160) } }
        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: pill.trailingIcon ? 3 : 0
            spacing: 8
            QQC2.Label { text: pill.text; color: pill.filled ? win.onFg : win.ink; font.pixelSize: 14 }
            Kirigami.Icon { visible: !!pill.trailingIcon; implicitWidth: 20; implicitHeight: 20; source: pill.trailingIcon; isMask: true; color: win.onFg }
        }
        MouseArea { id: pillArea; anchors.fill: parent; hoverEnabled: true; enabled: pill.enabled; cursorShape: Qt.PointingHandCursor; onClicked: pill.activated() }
    }
}
