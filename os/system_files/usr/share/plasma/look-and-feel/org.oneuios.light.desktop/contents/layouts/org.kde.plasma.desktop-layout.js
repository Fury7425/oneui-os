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

// left: logo + workspace dots + live activities | centre: search, app drawer, pinned | running | right: status + clock
const [logo] = pill("left", ["org.oneuios.button", "org.oneuios.workspaces", "org.oneuios.liveactivities"])
logo.currentConfigGroup = ["General"]
logo.writeConfig("icon", "oneui-os-logo-circle")
logo.writeConfig("logo", true)
logo.writeConfig("tooltip", "Desktops")
logo.writeConfig("command", "qdbus-qt6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Overview")
const [search, drawer, tasks] = pill("center", ["org.oneuios.button", "org.kde.plasma.kickoff", "org.oneuios.tasks"])
search.currentConfigGroup = ["General"]
search.writeConfig("icon", "oneui-os-search")
search.writeConfig("tooltip", "Search")
search.writeConfig("command", "qdbus-qt6 org.kde.krunner /App org.kde.krunner.App.toggleDisplay")
// right, like One UI / Windows 11: app tray icons | bell (notifications) | Wi-Fi·volume·battery (click = quick
// settings) | divider + clock (click = calendar)
const [tray] = pill("right", ["org.kde.plasma.systemtray", "org.kde.plasma.notifications",
                              "org.oneuios.quicksettings", "org.oneuios.clock"])
// Wi-Fi, Bluetooth, volume, battery and brightness live in quick settings; the tray keeps app icons and a few extras
// The tray adds every default item it hasn't seen yet, so list the moved ones as known but not shown.
// Only items that stay out of sight until they matter. An item that idles as "passive" (Disks & Devices, Input
// Method, KDE Connect, Vaults) lands in the overflow and brings back the "^" arrow the guide's pill doesn't have;
// KDE Connect stays one click away as quick settings' Multi Control tile.
const trayKeep = ["org.kde.plasma.clipboard", "org.kde.plasma.cameraindicator", "org.kde.plasma.keyboardindicator",
    "org.kde.plasma.keyboardlayout", "org.kde.plasma.printmanager"]
const trayMoved = ["org.kde.plasma.networkmanagement", "org.kde.plasma.bluetooth", "org.kde.plasma.volume",
    "org.kde.plasma.battery", "org.kde.plasma.brightness", "org.kde.plasma.notifications",
    "org.kde.plasma.mediacontroller", "org.kde.kscreen", "org.kde.plasma.weather",
    "org.kde.plasma.devicenotifier", "org.kde.plasma.manage-inputmethod", "org.kde.kdeconnect", "org.kde.plasma.vault"]
tray.currentConfigGroup = ["General"]
tray.writeConfig("extraItems", trayKeep)
tray.writeConfig("knownItems", trayKeep.concat(trayMoved))

// Kickoff as a One UI-style app drawer: grid everywhere, grid icon. Typing searches.
drawer.currentConfigGroup = ["General"]
drawer.writeConfig("icon", "oneui-os-apps")
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
