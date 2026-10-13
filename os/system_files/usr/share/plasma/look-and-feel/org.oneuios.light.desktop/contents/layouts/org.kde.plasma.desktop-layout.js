// OneUI OS default desktop (first login only): One UI / DeX taskbar as three floating pills on the
// bottom edge, a big clock on the desktop, the OneUI OS wallpaper.

function pill(alignment, widgets) {
    const panel = new Panel
    panel.location = "bottom"
    panel.alignment = alignment
    panel.lengthMode = "fit"
    panel.height = 56 // the mockup's pill; the Plasma Style's 28 px corners make it fully round
    panel.floating = true
    return widgets.map(w => panel.addWidget(w))
}

// left: ✦ + workspace dots + live activities | centre: app drawer + pinned/running | right: status + clock
const [spark] = pill("left", ["org.oneuios.button", "org.oneuios.workspaces", "org.oneuios.liveactivities"])
spark.currentConfigGroup = ["General"]
spark.writeConfig("icon", "oneui-os-spark")
spark.writeConfig("filled", true)
spark.writeConfig("tooltip", "Overview")
spark.writeConfig("command", "qdbus-qt6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Overview")
const [drawer, tasks] = pill("center", ["org.kde.plasma.kickoff", "org.kde.plasma.icontasks"])
// right, like One UI / Windows 11: app tray icons | bell (notifications) | Wi-Fi·volume·battery (click = quick
// settings) | divider + clock (click = calendar)
const [tray] = pill("right", ["org.kde.plasma.systemtray", "org.kde.plasma.notifications",
                              "org.oneuios.quicksettings", "org.oneuios.clock"])
// Wi-Fi, Bluetooth, volume, battery and brightness live in quick settings; the tray keeps app icons and a few extras
// The tray adds every default item it hasn't seen yet, so list the moved ones as known but not shown.
const trayKeep = ["org.kde.kdeconnect", "org.kde.plasma.vault", "org.kde.plasma.clipboard", "org.kde.plasma.devicenotifier",
    "org.kde.plasma.cameraindicator", "org.kde.plasma.keyboardindicator", "org.kde.plasma.keyboardlayout",
    "org.kde.plasma.manage-inputmethod", "org.kde.plasma.printmanager"]
const trayMoved = ["org.kde.plasma.networkmanagement", "org.kde.plasma.bluetooth", "org.kde.plasma.volume",
    "org.kde.plasma.battery", "org.kde.plasma.brightness", "org.kde.plasma.notifications",
    "org.kde.plasma.mediacontroller", "org.kde.kscreen", "org.kde.plasma.weather"]
tray.currentConfigGroup = ["General"]
tray.writeConfig("extraItems", trayKeep)
tray.writeConfig("knownItems", trayKeep.concat(trayMoved))

// Kickoff as a One UI-style app drawer: grid everywhere, grid icon. Typing searches.
drawer.currentConfigGroup = ["General"]
drawer.writeConfig("icon", "view-app-grid-symbolic")
drawer.writeConfig("favoritesDisplay", 0)
drawer.writeConfig("applicationsDisplay", 0)
drawer.writeConfig("showActionButtonCaptions", false) // mockup drawer has no power footer; keep it icon-only

tasks.currentConfigGroup = ["General"]
tasks.writeConfig("launchers", [
    "preferred://filemanager",
    "preferred://browser",
    "applications:org.kde.konsole.desktop",
    "applications:systemsettings.desktop",
    "applications:org.kde.discover.desktop",
])

for (const desktop of desktopsForActivity(currentActivity())) {
    desktop.wallpaperPlugin = "org.kde.image"
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]
    desktop.writeConfig("Image", "file:///usr/share/wallpapers/OneUIOS/")
    // left column from the mockup (300 px wide, 12 px gaps): big clock, then weather, batteries, calendar cards
    // sizes as the desktop's 16 px grid stores them; overlapping requests get shoved sideways
    desktop.addWidget("org.oneuios.bigclock", 16, 16, 304, 336)
    desktop.addWidget("org.kde.plasma.weather", 16, 352, 304, 224)
    desktop.addWidget("org.oneuios.batteries", 16, 576, 304, 160)
    desktop.addWidget("org.kde.plasma.calendar", 16, 736, 304, 304)
}
