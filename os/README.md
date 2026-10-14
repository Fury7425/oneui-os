# OneUI OS: a Linux that feels like Samsung made it

This folder is the build system for OneUI OS, a Galaxy Book-flavoured Linux. It uses the mockup (`../mockup`) for the look and the reverse-engineering notes (`../docs`) to decide which Samsung features to replace and how. "One UI" is Samsung's trademark: the name is fine for personal use, but pick another before you publish ISOs (see [Legal](#8-legal)).

- **Base:** Fedora Kinoite 44 (KDE Plasma 6.6, atomic) via Universal Blue's `kinoite-main` image
- **Delivery:** a bootc container image, built by GitHub Actions, turned into an installer ISO
- **First boot:** Plasma Setup, restyled to One UI with "look", "Galaxy features" and "You're all set" pages
- **Hardware target:** Galaxy Book4/5 (tested design target: your Galaxy Book4 Pro 14", `NT940XGQ`, Meteor Lake)

---

## 1. Which base, and why

I compared Fedora Atomic KDE, Arch, and Ubuntu/Debian for three things: Galaxy Book hardware, a new user coming from Windows, and how hard it is for one person to run a distro.

| | Fedora Atomic KDE (chosen) | Arch (archiso + Calamares) | Ubuntu / Debian |
|---|---|---|---|
| Galaxy Book driver (`samsung-galaxybook`, kernel 6.15+) | Yes, kernel 7.x | Yes, newest kernel | Ubuntu HWE yes, Debian stable no |
| Book4 webcam (kernel 6.17 + libcamera 0.5.2+) | Yes since Fedora 43 | Yes | Ubuntu needs a source build for Book5 |
| Secure Boot on, no BIOS changes | Yes (signed shim) | No, you turn it off or sign everything yourself | Yes |
| An update can break the system | No: new image applied on reboot, old one kept for rollback | Yes (rolling release) | Rarely |
| Work to run the distro | Edit a `Containerfile`, GitHub builds daily, PCs update from your image | Run package repos, an installer, and an ISO pipeline | Run a PPA and remaster ISOs |
| First-boot "phone-style" setup | Plasma Setup (Fedora 44+), accepts custom pages | You build it | You build it |

Why KDE Plasma rather than GNOME or a custom shell:
- Your three-pill taskbar is built into Plasma: floating panels with "fit content" width, one per pill. GNOME needs extensions, and they break on every GNOME release.
- Plasma behaves the way Windows users expect (Start-style launcher, Alt+Tab, Win+arrow snapping), and every setting has a GUI.
- Hyprland + Quickshell could copy the mockup pixel for pixel and uses less RAM, but it isn't friendly to new users and you would have to rebuild Settings, display, Wi-Fi, and Bluetooth UIs yourself.

Lightweight choices in this image: power-profiles-daemon instead of tuned (C instead of Python), Baloo indexes file names only, no Plasma splash, apps arrive as Flatpaks instead of a bloated base.

---

## 2. What's in this folder

```
os/
├─ Containerfile                 image recipe: base, then kmod stage, then final stage
├─ build_files/
│  ├─ build.sh                   packages, font, theme defaults, branding, services
│  └─ kmod.sh                    builds + signs the Galaxy Book speaker driver (throwaway stage)
├─ disk_config/iso.toml          installer ISO settings (no account step; points installs at your image)
├─ test/                         try the look in a Hyper-V live VM (vm.ps1, try-live.sh)
├─ mok.key                       PRIVATE module signing key (gitignored, back it up)
└─ system_files/                 copied over / in the image
   ├─ etc/xdg/kdeglobals         default theme, fonts, auto dark mode (colours appended at build)
   ├─ etc/xdg/{kwinrc,krunnerrc,ksplashrc,baloofilerc,kscreenlockerrc,kded5rc}
   ├─ etc/xdg/autostart/oneui-os-firstlogin.desktop + usr/libexec/oneui-os-firstlogin
   │                             first login: undo Plasma Setup's Fedora theme pick, apply OneUI OS + pills
   ├─ usr/lib/plasmalogin/defaults.conf   login screen wallpaper (Plasma Login Manager)
   ├─ usr/share/plasma/desktoptheme/oneui-os/   Plasma Style: pill panels, 28 px popups and cards
   ├─ etc/fonts/local.conf       same fonts in GTK and Flatpak apps
   ├─ usr/share/color-schemes/   OneUIOSLight/Dark, generated from your mockup's oklch tokens
   ├─ usr/share/plasma/look-and-feel/org.oneuios.{light,dark}.desktop/
   │                             global themes; light one carries the three-pill layout script
   ├─ usr/share/plasma/packages/org.oneuios.plasmasetup.{look,galaxy,done}/
   │                             extra Plasma Setup pages; done/Skin.qml restyles the setup frame
   ├─ usr/share/wallpapers/OneUIOS/   your mockup's ribbon wallpaper, light + dark
   ├─ usr/libexec/galaxybook-setup      per-laptop fixes (mic driver, speaker key)
   ├─ usr/lib/systemd/system/    galaxybook-setup, max98390 speaker setup, default Flatpaks
   └─ usr/share/oneui-os/mok.der       public half of the signing key

../.github/workflows/            at the repo root, because GitHub only reads workflows there
├─ build.yml                     builds and pushes the image on every push and daily
└─ build-iso.yml                 makes the ISO on demand
```

---

## 3. How it feels like Samsung from the first second

1. **Power on.** The Galaxy Book firmware shows the SAMSUNG logo. Fedora's boot splash (Plymouth `bgrt`) keeps that firmware logo on screen with a spinner under it, so the whole boot looks like Samsung's own. Nothing Samsung-owned ships in the ISO; the logo is read from the laptop's firmware.
2. **Installer.** Pick a disk and a time zone. There are no account questions; those move to first boot.
3. **First boot (Plasma Setup).** A Galaxy-style **"Hello / 안녕하세요 / Bonjour…"** greeting on the blurred wallpaper with a round arrow, then one glass card: language, keyboard, Wi-Fi, your account, **Choose a look** (light or dark and a colour palette, applied as you pick), time zone, **Galaxy features** (Quick Share, phone, Buds, battery protection, plus the one-time speaker step if needed) and **You're all set**. All of it uses the OneUI OS colours and the Pretendard font.
4. **First login.** Three floating pills at the bottom, a big desktop clock, the ribbon wallpaper, Papirus icons, and dark mode from sunset to sunrise (One UI's "Dark mode: as scheduled").

---

## 4. Build it, step by step

### Step 0: What you need

- A GitHub account, `git`, and optionally the GitHub CLI (`winget install GitHub.cli`).
- Optional, only for local builds: Linux with podman and about 40 GB free (on Windows: Fedora in WSL). WSL has been removed from this PC, so GitHub Actions is the route here.

### Step 1: Make it yours

Placeholder names you'll probably change:

| What | Where |
|---|---|
| OS name shown in Settings, setup and the installer | `NAME` / `PRETTY_NAME` in `build_files/build.sh` |
| Global theme names | `system_files/usr/share/plasma/look-and-feel/*/metadata.json` |
| Logo | `system_files/usr/share/icons/hicolor/scalable/apps/oneui-os-logo.svg` |
| Default apps | `oneui-os-flatpaks.service` |
| MokManager password (`oneui-os`) | `build.sh` (`--generate-hash`) and the Galaxy page text |

### Step 2: Keep the signing key safe

The Galaxy Book4/5 speaker driver isn't in the Linux kernel yet, so the image builds it and signs it with **your** key. `mok.key` (private) has already been generated in this folder and is gitignored. `system_files/usr/share/oneui-os/mok.der` (public) gets committed.

- Back up `mok.key` somewhere safe, such as a password manager. Never commit it.
- If you lose it, generate a new pair. Every existing install then has to enroll the new key once.

To regenerate it:

```sh
openssl req -new -x509 -newkey rsa:2048 -nodes -days 3650 -sha256 \
  -subj "/CN=OneUI OS kernel module signing key" \
  -addext "basicConstraints=critical,CA:FALSE" -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=codeSigning,1.3.6.1.4.1.2312.16.1.2" \
  -outform DER -keyout mok.key -out system_files/usr/share/oneui-os/mok.der
```

### Step 3: Publish the repo and build the image

The repo is the whole project folder (`os/`, `mockup/`, `docs/`; `recon/` and `tools/` are gitignored). Once it exists on GitHub, give the build its signing key, from the project folder:

```sh
gh secret set MOK_KEY < os/mok.key
```

Private repos get 2,000 free Actions minutes a month, and a full image build takes a good share of an hour. If the daily build eats too much of that, delete the `schedule:` lines in `.github/workflows/build.yml` and build on push only, or make the repo public (public repos get unlimited minutes).

1. Open the repo's **Actions** tab. **Build image** starts on every push; it also runs daily so installs pick up Fedora and KDE updates.
2. When it's green, go to your GitHub profile → **Packages** → `oneui-os` → **Package settings** → **Change visibility** → **Public**. Installed PCs pull updates without logging in, and the ISO builder needs to pull the image too.

### Step 4: Build the ISO

**On GitHub:** **Actions** → **Build ISO** → **Run workflow**. When it finishes, download the `oneui-os-iso` artifact. The zip contains `bootiso/install.iso`.

**Locally** (Linux with podman, from this `os` folder):

```sh
sudo podman build --secret id=mok_key,src=mok.key -t localhost/oneui-os:latest .
mkdir -p output
sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./disk_config/iso.toml:/config.toml:ro \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type anaconda-iso --use-librepo=True localhost/oneui-os:latest
# result: output/bootiso/install.iso
```

For local-only testing, remove the `%post … %end` block from `iso.toml`. Otherwise the installed system switches itself to `ghcr.io/YOUR_GITHUB_USER/oneui-os`, which doesn't exist.

### Step 5: Test in a VM first

**Just the look, no build needed:** in an admin PowerShell, run `test\vm.ps1`. It downloads the Fedora KDE live ISO and creates a Hyper-V VM with this folder attached as a small `ONEUIOS` disk. In the live session, open a terminal and run `udisksctl mount -b /dev/disk/by-label/ONEUIOS`, then `bash /run/media/liveuser/ONEUIOS/test/try-live.sh`. To pick up theme edits, shut the VM down and run `vm.ps1` again.

**The full image:**

In Hyper-V (included with Windows 11 Pro): create a **Generation 2** VM, set Secure Boot template to **Microsoft UEFI Certificate Authority**, give it 4 GB+ RAM and a 64 GB disk, and attach the ISO. Check the setup flow, the taskbar, and light/dark switching.

To iterate without rebuilding the ISO, push your change, wait for **Build image**, then run this on the test machine:

```sh
sudo bootc upgrade && systemctl reboot
```

The panel layout only applies to a fresh profile. Test layout changes with a new user, or reset yours:

```sh
plasma-apply-lookandfeel --apply org.oneuios.light.desktop --resetLayout
```

### Step 6: Install on the Galaxy Book

Before you wipe or shrink Windows:
1. **Colour profiles.** Copy `C:\Windows\System32\spool\drivers\color\SDC4189*.icm` to a USB stick. Your docs (12) found `SDC4189` as this panel's ID. They're Samsung's files, so use them on your own machine and don't ship them in the ISO.
2. **BitLocker.** Save the recovery key (aka.ms/myrecoverykey). To dual boot, shrink C: in Disk Management.
3. **BIOS updates.** Samsung only ships them for Windows. Keeping a small Windows partition is the easy way to stay updated.

Then install:
1. Write the ISO to a USB stick with Fedora Media Writer ("Select .iso file") or Rufus (choose **DD mode** when asked).
2. Power on and tap **F10** for the boot menu (**F2** opens BIOS setup). If the USB stick doesn't appear, turn off Fast BIOS Mode in F2. **Leave Secure Boot on.**
3. In the installer, pick the disk and click **Begin Installation**, then reboot.
4. Plasma Setup runs. If the Galaxy features page shows the speaker notice, reboot once. On the blue **MokManager** screen choose **Enroll MOK → Continue → Yes**, type `oneui-os`, then **Reboot**. Speakers work from then on.

---

## 5. The UI, step by step (mockup → Plasma)

**Style and motion guide:** `mockup/motion.html` (published as the "OneUI OS Motion" artifact). All UI work follows it: tokens, glass rules, curves and springs, choreography, palette roles, icon rules, and the boot/setup/lock flows.

What's already in the image and what's left. "Checked" means seen working in a Fedora KDE 44 VM (Plasma 6.6.4)
with only these files applied; the per-view detail and next steps are in [`docs/ui-parity.md`](../docs/ui-parity.md).

| Mockup element | Plasma piece | Where | Status |
|---|---|---|---|
| Boot logo | Plymouth `bgrt` (Fedora's default): firmware logo + spinner | built in | Done (VM has no firmware logo to show) |
| Login screen | Plasma Login Manager (replaced SDDM in F44) on the OneUI OS wallpaper | `usr/lib/plasmalogin/defaults.conf` | Checked |
| First-boot setup | Plasma Setup restyled to the guide: the landing is the "Hello" greeting on the blurred wallpaper with a round arrow; steps sit on one 34 px glass card (title left, Back, progress dots, Next pill, resizes per step). Pages: language, keyboard, Wi-Fi, account, `look` (light/dark + palette, applied live), time, `galaxy`, `done` ("You're all set"). Fedora's dark-mode page and KDE's "Completed!" page are removed | `plasmasetup.*` (`done/Skin.qml`), `build.sh`, `share/oneui-os/wall-blur-*.png` | Checked (Finish not clicked in the VM) |
| Setup's look step | Applies OneUI OS light/dark and the accent; Plasma Setup copies kdeglobals to the new account. `oneui-os-firstlogin` still swaps a Fedora theme for ours if one slips through | `look`, `oneui-os-firstlogin` | Checked |
| Fedora "Welcome" window | Turned off (KF6 kded still reads `kded5rc`) | `etc/xdg/kded5rc` | Checked |
| Taskbar as three floating pills | 3 bottom panels, `lengthMode = "fit"`, `floating`, 56 px, 12 px from the edges, the guide's soft shadow under each pill. They stay pills when a window touches them (Plasma would turn them into a plain bar; `build.sh` patches `Panel.qml`, and the build fails if that line moves) | `layout.js`, `build.sh`, `widgets/panel-background.svg`, `test/panel-shadow.py` | Close: checked after a plasmashell restart; on brand-new accounts the VM showed no panels (open issue, see `docs/ui-parity.md`) |
| Left pill: logo + workspaces + live activities | `org.oneuios.button` (round logo, opens Overview), `org.oneuios.workspaces` (dots: current, busy, empty), `org.oneuios.liveactivities` (now playing chip with cover + EQ; red mic chip with timer) | `plasmoids/`, `layout.js` | Checked (timer chip: not yet) |
| Centre pill: search, apps, pinned and running | `org.oneuios.button` (search = KRunner) + Kickoff grid + `org.oneuios.tasks` (38 px icons, running dot 4 px / focused 12 px, divider before running-only apps, grow/shrink on add/remove) | `plasmoids/`, `layout.js` | Checked |
| Right pill: bell · Wi-Fi/volume/battery · clock | Tray (app icons) + Notifications (bell) + `org.oneuios.quicksettings` (status group, click = quick panel; the battery number splits ink/On text at the charge edge) + `org.oneuios.clock` (click = calendar) | `layout.js`, `build.sh` | Checked: no "^" overflow. Tray plasmoids are limited to ones that stay hidden until needed; Discover's update icon and Xwayland Video Bridge don't autostart |
| Pill / 28 px radius family, glass | Plasma Style `oneui-os`: pills and popups are the guide's floating glass: the scheme's view colour (white in light) at 62 %, KWin blur (strong enough to flatten 12 px stripes, like the guide's 40 px), saturation 180 % with contrast left at 1 (Breeze's 0.2 greys the blur out), a 1 px hairline and a 1 px light edge inside the top; popups have 32 px corners; no underline under an open applet. Tooltips are the guide's 28 px glass pill after 350 ms, centre pill only | `desktoptheme/oneui-os`, `etc/xdg/plasmarc`, `oneuios_popups` | Checked against the prototype (same stripe pattern behind both), light and dark |
| Popup motion | KWin effect `oneuios_popups`: taskbar popups and notifications fade 180 ms and rise 16 px from 94 % on a spring; exits 200 ms on the Exit curve. Replaces Sliding and Fading popups | `kwin-wayland/effects/oneuios_popups`, `kwinrc` | Loaded in the VM (llvmpipe needs `KWIN_EFFECTS_FORCE_ANIMATIONS=1`) |
| Big clock | `org.oneuios.bigclock`: date above, "09" over "41" in light 124 px | `plasmoids/`, `layout.js` | Checked |
| Weather / batteries / calendar cards | Weather Report, `org.oneuios.batteries` (a ring per device), Calendar | `plasmoids/`, `layout.js` | Close (weather needs a location; calendar is a month grid) |
| Text straight on the wallpaper (clock) | Complementary colours = ink on light in the light scheme | `OneUIOSLight.colors` | Checked |
| Finder ("What are you looking for?") | KRunner floating in the centre, 28 px glass | `krunnerrc` | Close |
| App drawer | Kickoff popup, grid, 28 px glass | `layout.js` | Close (sidebar + footer remain) |
| Notification pill stack | Plasma notifications in 28 px glass | Plasma Style | Close (icon on the right, not a pill row) |
| Quick panel (One UI 9) | `org.oneuios.quicksettings`: time header with edit/power/settings, Wi-Fi and Bluetooth wells, tile frame (airplane, DND, Quick Share, Multi Control, performance, eye comfort, screen recorder, hotspot; handle opens keyboard light, screenshot, lock), sliders with dark mode and mute beside them, media output row, mic-in-use row. Material Symbols glyphs; rows rise in bottom-first | see U3 | Checked (light and dark) |
| DeX window buttons | Breeze, minimise/maximise/close on the right | `kwinrc` | Close; Aurorae theme for exact |
| Desktops overview | KWin Overview (Meta+W) | built in | Close |
| Colours (your oklch tokens) | `OneUIOSLight/Dark.colors` | `color-schemes/` | Checked |
| Font | Pretendard (Samsung's fonts can't be redistributed) | `build.sh`, `kdeglobals` | Checked |
| Dark mode on a schedule | Automatic global theme switching | `kdeglobals` | Done (not exercised in the VM) |

### U1: Work live, then copy into files

Change things in System Settings on a test install, then see what changed:

```sh
cat ~/.config/kdeglobals
cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc   # panels and widgets
```

Move system-wide defaults into `system_files/etc/xdg/<file>`, and panel or widget settings into `layout.js` as `writeConfig(...)` calls.

### U2: Plasma Style `oneui-os` (pills, popups, cards)

`system_files/usr/share/plasma/desktoptheme/oneui-os/` holds only what differs from Breeze; everything else falls back to it.
Three hand-written SVGs share one shape (28 px corners, glass fill in the colour scheme's Window colour, a 1 px edge in
its text colour at 12 %): `widgets/panel-background.svg` (72 %), `dialogs/background.svg` (84 %, popups and
notifications), `widgets/background.svg` (62 %, desktop cards). Both global themes select it in `contents/defaults`.

Rules learned the hard way (each one hid the panels or the whole theme without an error message):
- `metadata.json` needs `"X-Plasma-API": "5.0"`.
- No double hyphen inside an XML comment: QtSvg rejects the whole file.
- Put `class` and `fill` on every shape; QtSvg doesn't pass a group's colour class down.
- Floating panels need `mask-*` elements, or they stay invisible at login.

Check an SVG before restarting plasmashell: `QT_QPA_PLATFORM=offscreen ksvgtopng 400 120 file.svg out.png`.

### U3: OneUI OS plasmoids

Small QML widgets in `system_files/usr/share/plasma/plasmoids/org.oneuios.*`, built only on Plasma's own backends
(NetworkManager, BlueZ, PipeWire/PulseAudio, KWin, MPRIS, power-profiles, notifications):

| Plasmoid | What it is |
|---|---|
| `quicksettings` | Right pill status group; click opens the One UI quick panel |
| `liveactivities` | Left pill chips: now playing (click = play/pause), microphone recording timer |
| `workspaces` | Workspace dots; click or scroll switches desktop |
| `button` | Round button running a command (logo = Overview, search = KRunner) |
| `tasks` | Centre pill apps: pinned, then running; running dots; right click: new window, pin, close |
| `bigclock` | Desktop clock, hours over minutes |
| `batteries` | Desktop card with a ring per battery (laptop, Bluetooth devices) |

The quick panel matches One UI 9 (the reference is the motion prototype, `mockup/motion.html`): a time and date header, Wi-Fi and Bluetooth in two wells, the tile grid in its own rounded frame with a handle, sliders with a button beside each (dark mode next to brightness, mute next to volume). Tile glyphs are **Material Symbols Rounded, filled** (Apache-2.0), exported to SVG. Off tiles are a translucent circle; on tiles are a solid circle in the palette's "on" colour (white in dark Mono, ink in light Mono).

### U4: Colour palette for OneUI OS apps (reminder)

One UI's **Wallpaper and style → Color palette**: **Auto** (follows the wallpaper and light/dark), Mono (default), palettes taken from the wallpaper, and basic colours, plus **Apply palette to app icons**. Auto's extraction steps are in the guide's Color palette section; run them in a small user service that watches the wallpaper setting.

1. A "Wallpaper and style" page (in the Settings app or a KCM) that writes the accent colour to `kdeglobals`. Plasma 6 can already take the accent from the wallpaper; Kirigami's highlight colour follows it.
2. Wallpaper palettes: generate them with Material Color Utilities (Apache-2.0; quantise + score), four from the wallpaper plus fixed basic colours.
3. Every OneUI OS plasmoid and app reads the accent for its "on" state, switches, the nav pill and today in the calendar, and tints glass slightly toward it. The roles and lightness values are in the prototype's Color palette section.
4. Themed icons: on palette change, generate an `OneUIOS-Themed` icon theme (each app's monochrome glyph on the palette's tile tone, inheriting the normal theme) and switch to it.

### U5: Icon packs (reminder)

- **App icons:** try [OneUI4-Icons](https://github.com/mjkim0727/OneUI4-Icons) (GPL-3, based on Fluent, light and dark variants). Before shipping: check how many apps it covers, check that none of its icons are copied Samsung artwork, and pin a commit in `build.sh`. Keep Papirus as the fallback (`Inherits=`).
- **Quick panel and status glyphs:** Material Symbols Rounded, filled (see U3).
- **Themed icons:** see U4.
- **Not allowed:** Samsung's own One UI icons. They can't be redistributed, same as the fonts and logos (Step 8).

### U6: Boot, first boot, lock and power menu (reminder)

Designed in the guide's "Power on to desktop" section; each piece maps to a Plasma part:

- **Boot / restart / power off:** a Plymouth theme on the two-step plugin. Firmware logo first (like Fedora's bgrt theme), then the mark drawing its ribbon as animation frames and three dots as the throbber; "Restarting" / "Shutting down" under the mark.
- **First boot:** done: greeting, glass card, "look" and "You're all set" pages (see the table above). Left: the guide's switches on the Galaxy features rows, and the ribbon drawing on the final mark.
- **Lock and login:** one design for the look-and-feel `lockscreen` and the Plasma Login Manager greeter: clock on the sharp wallpaper, sign-in on the blurred one, fingerprint option if libfprint supports the power-key sensor.
- **Desktop arrival:** look-and-feel `splash` fades the blurred wallpaper out over the desktop.
- **Power menu:** look-and-feel `logout`: Lock, Sleep, Restart, Power off.

To try a change on a running system: copy the folder to `/usr/share/plasma/plasmoids/`, delete
`~/.cache/plasmashell/qmlcache`, then `systemctl --user restart plasma-plasmashell`. Errors land in `journalctl --user`.

### U7: Desktop widgets

`layout.js` places the mockup's left column (big clock, weather, batteries, calendar) at the mockup's coordinates.
The weather card shows "Configure…" until the user picks a location.

---

## 6. Galaxy Book optimization

### Done automatically by the image

- **Kernel driver `samsung-galaxybook`** (in Fedora's kernel): keyboard backlight, performance modes, battery charge limit, firmware toggles, Fn hotkeys.
- **power-profiles-daemon** instead of tuned. It drives Samsung's `platform_profile` directly, so Fn+F11 and Plasma's battery applet agree.
- **Speakers (Book4/5 Pro and Ultra, MAX98390 amps):** a community driver built into the image, plus the I2C setup service. Without it the speakers are silent.
- **Internal mic (Book4, Meteor Lake):** `galaxybook-setup` switches audio to the SOF driver (`dsp_driver=3`) on first boot. It takes effect from the second boot.
- **Webcam (Book4 IPU6):** libcamera + PipeWire from `kinoite-main`.
- **Korean input:** fcitx5-hangul is preinstalled. Enable it under **System Settings → Keyboard → Virtual Keyboard → Fcitx 5**, then add Hangul in the Fcitx settings.
- **Updates:** system updates download in the background and apply on the next reboot; Flatpak updates run on timers (both from `kinoite-main`).
- **Default apps:** Packet (Quick Share) and Galaxy Buds Manager install from Flathub once the laptop is online.

### Samsung Settings → OneUI OS

| Samsung feature (docs 01, 05, 02) | On OneUI OS |
|---|---|
| Battery protection (charge cap) | System Settings → Power Management → charge limit. Use **80** (Samsung's firmware accepts 50/60/70/80/90/100). |
| Performance mode (Silent / Optimized / High) | Battery applet power profile, or **Fn+F11** |
| Keyboard backlight | **Fn+F9**, or the slider in the battery applet |
| Camera and mic block | **Fn+F10** |
| Power on when lid opens / USB charging while off | `echo 1 \| sudo tee /sys/class/firmware-attributes/samsung-galaxybook/attributes/power_on_lid_open/current_value` (same for `usb_charging`) |
| Screen mode / colour profile | Copy your `SDC4189*.icm` to `~/.local/share/icc/`, then System Settings → Display → Color profile |
| Dolby Atmos | Not supported by the driver. EasyEffects (Flathub) is the substitute. |
| Quick Share | Packet. It works over Wi-Fi LAN only: Bluetooth on, both devices on the same Wi-Fi. No Wi-Fi Direct. |
| Phone Link, shared clipboard, notifications, SMS (Continuity) | KDE Connect (built in; install the KDE Connect app on the phone) |
| Galaxy Buds | Galaxy Buds Manager (battery, ANC, EQ); Buds batteries also show in Plasma |
| Multi Control | No Linux equivalent for Galaxy Tabs. KDE Connect gives remote input; Deskflow (Flathub) shares keyboard and mouse between PCs. |
| Camera Share | Not in 0.1. scrcpy `--video-source=camera` into v4l2loopback would need another kernel module like the speaker one. |
| Samsung Cloud / Gallery | Galaxy Gallery syncs to OneDrive; use OneDrive on the web or rclone |
| Samsung Update / BIOS | Windows only (see Step 6) |

### Display and battery tips

- **Scale:** the 14" 2880×1800 panel looks like your mockup at **150%**. Choose **175%** for larger text. Plasma Setup asks.
- **AMOLED:** the scheduled dark mode saves power at night. On battery, 60 Hz (System Settings → Display) saves more than any other single setting.
- **Wi-Fi 6 GHz:** your doc 13 shows Samsung's Windows service writes the 6 GHz (UHB) enable flag into a UEFI variable. Intel's Linux driver also reads UEFI regulatory variables, so 6 GHz may already work if Windows ran once. This is inferred, not verified.

### Troubleshooting

| Problem | Check |
|---|---|
| No speakers | `mokutil --sb-state`, `lsmod \| grep max98390`, `systemctl status max98390-hda-i2c-setup`. With Secure Boot on, the key must be enrolled: `sudo /usr/libexec/galaxybook-setup`, then reboot and follow MokManager. Some Samsung BIOS updates wipe enrolled keys, so repeat after a BIOS update. |
| No microphone | `cat /etc/modprobe.d/galaxybook-mic.conf`, then reboot once. Delete the file to undo. |
| Webcam black or wrong colours | Some Book4 sensors need the ov02c10 26 MHz clock fix (`ov02c10-26mhz-fix` in Andycodeman's repo). Add it to `kmod.sh` the same way as the speaker driver. |
| Webcam missing in Chrome/Edge | Enable `chrome://flags/#enable-webrtc-pipewire-camera` |
| Webcam missing in Zoom/Teams desktop apps | They need a V4L2 relay; see `camera-relay` in Andycodeman's repo |
| A bad update | Pick the previous entry in the boot menu (press Esc while booting), or `sudo bootc rollback` |

---

## 7. Updates and upkeep

- **Your side:** every push to `main` builds a new image, and a daily build picks up Fedora fixes. Installed PCs stage it in the background and switch on their next reboot.
- **Fedora 45** is due around 2026-10-20 (Plasma 6.7, kernel 7.2). Change `BASE` in the `Containerfile` from `:44` to `:45` after it ships.
- **When the speaker driver lands upstream:** delete `kmod.sh`, the `kmod` stage, `max98390-*` files, and the MOK steps.

---

## 8. Legal

- "OneUI OS" uses Samsung's "One UI" trademark. That's fine in a private repo and on your own laptop. Before you publish ISOs or make the repo public, pick a new name: change `NAME`/`PRETTY_NAME` in `build.sh` and the theme names (Step 1).
- Don't ship Samsung's logos, fonts (Samsung One, Sharp Sans, Simplified), or colour files (ICC/LUT). Saying "for Galaxy Book laptops" to describe compatibility is fine.
- The SAMSUNG logo at boot is fine: it comes from the user's own firmware.
- Pretendard is OFL, Papirus is GPL-3, and the speaker driver is GPL-2 (credit Andycodeman/samsung-galaxy-book-linux-fixes in your release notes).
- Material Symbols Rounded (Apache-2.0) ship as `oneui-os-ms-*` glyphs (quick panel, setup). Planned: OneUI4-Icons (GPL-3) if it passes the provenance check, Material Color Utilities (Apache-2.0) for palettes. Samsung's own icons are never shipped.

---

## 9. Not done yet (in priority order)

1. **Not build-tested.** The first **Build image** run and a VM install are the real tests. The most likely failure points are the `kernel-devel` version match in `kmod.sh` and the installer with its user step turned off (if Anaconda refuses to continue, remove `Users` from `disable` in `iso.toml`).
2. The gaps listed in `docs/ui-parity.md`.
3. Colour palette and themed app icons (U4).
4. App icon theme: evaluate OneUI4-Icons (U5).
5. Boot animation, lock/login and power menu to the guide (U6).
6. A "Galaxy Book" settings page for lid and USB-charging toggles and battery health, instead of `tee` commands.
7. Live ISO (Universal Blue's Titanoboa) so people can try before installing. The Anaconda installer still shows Fedora artwork.
8. Sign the image with cosign before sharing it widely.

---

## Sources

- Kernel docs, Samsung Galaxy Book driver: https://docs.kernel.org/admin-guide/laptops/samsung-galaxybook.html
- Galaxy Book speaker, mic, and webcam fixes: https://github.com/Andycodeman/samsung-galaxy-book-linux-fixes
- Fedora 44 Plasma Setup change: https://fedoraproject.org/wiki/Changes/Unified_KDE_OOBE
- Plasma Setup (custom modules): https://invent.kde.org/plasma/plasma-setup
- Fedora IPU6 camera support: https://fedoraproject.org/wiki/Changes/IPU6_Camera_support
- Universal Blue image template: https://github.com/ublue-os/image-template
- Plasma scripting API: https://develop.kde.org/docs/plasma/scripting/api/
- Packet (Quick Share for Linux): https://github.com/nozwock/packet
- Pretendard: https://github.com/orioncactus/pretendard
