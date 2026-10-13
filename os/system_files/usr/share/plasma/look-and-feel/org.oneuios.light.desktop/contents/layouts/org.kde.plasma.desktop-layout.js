// OneUI OS default desktop (first login only): One UI / DeX taskbar as three floating pills on the
// bottom edge, a big clock on the desktop, the OneUI OS wallpaper.

function pill(alignment, widgets) {
    const panel = new Panel
    panel.location = "bottom"
    panel.alignment = alignment
    panel.lengthMode = "fit"
    panel.height = 2 * Math.ceil(gridUnit * 2.75 / 2)
    return widgets.map(w => panel.addWidget(w))
}

// left: workspaces + live activity (media) | centre: app drawer + pinned/running | right: status + clock
pill("left", ["org.kde.plasma.pager", "org.kde.plasma.mediacontroller"])
const [drawer, tasks] = pill("center", ["org.kde.plasma.kickoff", "org.kde.plasma.icontasks"])
pill("right", ["org.kde.plasma.systemtray", "org.kde.plasma.digitalclock"])

// Kickoff as a One UI-style app drawer: grid everywhere, grid icon. Typing searches.
drawer.currentConfigGroup = ["General"]
drawer.writeConfig("icon", "view-app-grid-symbolic")
drawer.writeConfig("favoritesDisplay", 0)
drawer.writeConfig("applicationsDisplay", 0)

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
    desktop.addWidget("org.kde.plasma.digitalclock", gridUnit, gridUnit, gridUnit * 16, gridUnit * 10)
}
