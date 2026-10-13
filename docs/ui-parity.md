# UI parity: mockup vs OneUI OS on Plasma

How close the OS gets to the mockup (`mockup/renders/*.png`, 1920×1200 logical). Checked in a Hyper-V VM
(Fedora KDE 44 installed from the live ISO, Plasma 6.6.4, llvmpipe software rendering, 1920×1200 at 100 %) after
applying only the files in `os/` with `os/test/try-live.sh`, then running first boot (Plasma Setup) for a new
account. Screenshots were kept in `os/test/shots/` during the work and deleted at cleanup.

**matches** = reads as the render. **close** = right idea, visible differences. **missing** = not there yet.
L = light, D = dark.

## Open issue first: panels on brand-new accounts

On a fresh account the three pills did not appear in the VM, on the first login or on the second. They appeared,
correctly styled and floating, as soon as plasmashell was restarted in a running session, and on later logins of
an account that had been through such a restart. The same session logs showed the shell starved at startup:
xdg-desktop-portal calls timing out (25 s), plasmashell blocked in `fdatasync` for about two minutes with under
1 s of CPU, and widget positions on the desktop lost. A first-login plasmashell restart made it worse (the stalled
shell was killed and the layout was lost), so the image does not do that.

Next step: install the built image on the Galaxy Book (or any machine with a GPU and an SSD) and check the first
login. If the pills are missing there too, test with `panel.floating` and the Plasma Style switched off one at a
time, then report it to KDE with the startup log.

## First boot

| View | Element | L | D | Status | Next step |
|---|---|---|---|---|---|
| Boot | Plymouth `bgrt` (firmware logo + spinner) | – | – | matches (Fedora default) | Check on the laptop; a VM has no firmware logo |
| Plasma Setup landing | OneUI OS wallpaper | ✓ | ✓ | matches | |
| Plasma Setup landing | "Welcome to Plasma Desktop" title, small Breeze button | ✓ | ✓ | close | Hard-coded in `plasma-setup`; needs an upstream option or a patch |
| Hello page | Multi-language greeting, 5 gridUnits bold, rises in, fades out | ✓ | – | matches | |
| Hello / every page | Wizard frame, Back/Next buttons, page title | ✓ | ✓ | close | Plasma Setup's own frame; can't be restyled by a module |
| Galaxy features page | One UI list card: 26 px card, coloured 34 px circles, inset separators | ✓ | ✓ | matches | |
| Completed page | KDE's Konqi artwork | ✓ | ✓ | missing | Replace `org.kde.plasmasetup.finished` with a OneUI OS page |
| Setup's dark switch | New account gets OneUI OS dark, not Fedora's theme | – | ✓ | matches | |
| Login screen (Plasma Login Manager) | OneUI OS wallpaper, clock | ✓ | – | close | Clock is 12 h and bold; avatar/buttons are stock |
| Lock screen | OneUI OS wallpaper, ink clock | ✓ | ✓ | close | Same clock styling as login |
| First login | Fedora "Welcome Center" | ✓ | ✓ | matches (off) | |

## Desktop (`desktop-*.png`)

| Element | L | D | Status | Next step |
|---|---|---|---|---|
| Wallpaper (ribbon, light/dark) | ✓ | ✓ | matches | |
| Three floating pills, 56 px, full round ends, 1 px edge | ✓ | ✓ | close | See the open issue above |
| Left pill: ✦ button + workspace dots + now-playing chip (cover, title, EQ) | ✓ | ✓ | matches | |
| Left pill: red recording chip with timer | – | – | close | Shows while an app records the microphone; not exercised in the VM |
| Left pill: countdown timer chip | – | – | missing | Read KClock timers over D-Bus in `liveactivities` |
| Centre pill: drawer button + pinned/running apps | ✓ | ✓ | close | Mockup also has a search button first; app icons are Papirus, not the mockup's squircles (icon theme generator drafted) |
| Right pill: bell · Wi-Fi/volume/battery pill · "9:41 / Mon 12" | ✓ | ✓ | matches | |
| Big clock: date above, "09" over "41" light 124 px | ✓ | ✓ | matches | |
| Clock text contrast on the wallpaper | ✓ | ✓ | matches | Light scheme's Complementary colours now ink-on-light |
| Weather card | ✓ | ✓ | close | Shows "Configure…" until a location is set; ask for it in Plasma Setup |
| Batteries card (a ring per device) | ✓ | ✓ | matches | VM has only the laptop battery; Bluetooth devices add rings |
| Calendar card ("Today · 2 events") | ✓ | ✓ | close | Month grid instead of an agenda list |
| Card shape: 28 px glass with edge | ✓ | ✓ | matches | |
| Quick settings panel (click the status group) | ✓ | – | matches | Wi-Fi/Bluetooth pills, 8 toggles, brightness and volume sliders all work in the VM; dark-mode look not captured |
| Window chrome (DeX circular buttons, close in a tinted circle) | ✓ | – | close | Breeze buttons; an Aurorae theme would match exactly |

## Other views

| View | Element | L | D | Status | Next step |
|---|---|---|---|---|---|
| Finder (`finder-*`) | Centred search popup, 28 px glass | ✓ | – | close | KRunner: search on top, list below; mockup has suggestions/chips above a bottom field |
| App drawer (`drawer-*`) | 28 px glass popup, app grid | ✓ | – | close | Kickoff keeps its category sidebar and power footer; footer captions are hidden |
| Notifications (`notifs-*`) | 28 px glass popup | ✓ | – | close | Plasma layout (icon right); mockup is a pill row with the app icon left |
| Overview (`overview-*`) | Desktop strip, search, scaled desktop | ✓ | – | close | KWin Overview; three desktops are set in `kwinrc` |

## Tokens

The colour schemes come from `mockup/tokens-and-components.css`: ink `#18181e`, window `#f0f0f3` (light), glass
opacities 62/72/84 %, 28 px card radius, 1 px line at 12 %. Text on glass and on the wallpaper uses ink or ink at
70 % (secondary), about 7:1 on the light glass.

## How to re-check

1. `os/test/vm.ps1 -Persistent`, install Fedora KDE 44, then apply `os/` with `try-live.sh` as root before first boot.
2. Screenshots: spectacle hangs in a user session over ssh; use the vmconnect window, or Hyper-V's
   `Msvm_VirtualSystemManagementService.GetVirtualSystemThumbnailImage` (RGB565) from the host.
3. Check Plasma Style SVGs before restarting plasmashell: `QT_QPA_PLATFORM=offscreen ksvgtopng 400 120 file.svg out.png`.
4. Fedora names: `qdbus-qt6` (not `qdbus6`); KF6 kded reads `kded5rc`.
