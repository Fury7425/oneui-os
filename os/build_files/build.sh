#!/usr/bin/bash
# Runs once inside the image build. Everything here ships in every install.
set -ouex pipefail

cp -avf /ctx/system_files/. /
chmod 755 /usr/libexec/galaxybook-setup /usr/libexec/oneui-os-firstlogin
# Same three-pill layout for a first login in dark mode (one source file, copied at build time).
cp -r /usr/share/plasma/look-and-feel/org.oneuios.light.desktop/contents/layouts \
    /usr/share/plasma/look-and-feel/org.oneuios.dark.desktop/contents/

### Packages
# papirus: rounded, colourful icons closest to One UI. jetbrains-mono: the terminal font from the mockup.
# i2c-tools + mokutil: Galaxy Book speaker setup. plasma-setup: the first-boot wizard (already in F44 Kinoite).
dnf5 -y install papirus-icon-theme jetbrains-mono-fonts i2c-tools mokutil plasma-setup kde-connect unzip

# power-profiles-daemon drives Samsung's platform_profile directly, so Fn+F11 and Plasma's battery
# applet stay in sync. It is also much lighter than tuned (a Python daemon).
if rpm -q tuned-ppd; then dnf5 -y swap tuned-ppd power-profiles-daemon; else dnf5 -y install power-profiles-daemon; fi
if rpm -q tuned; then dnf5 -y remove tuned; fi

### Font: Pretendard (OFL), Latin + Hangul, close to Samsung One. Samsung's own fonts can't be redistributed.
curl -fsSLo /tmp/pretendard.zip https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip
echo "04be351a74d6bf7d60c480a3087e51d185485d35a52023142af1df19eb8c428a  /tmp/pretendard.zip" | sha256sum -c
unzip -j /tmp/pretendard.zip public/variable/PretendardVariable.ttf -d /usr/share/fonts/pretendard
fc-cache -f /usr/share/fonts/pretendard

### Look: default colours must live in kdeglobals itself, or Qt apps start in Breeze until the theme is re-applied.
cat /usr/share/color-schemes/OneUIOSLight.colors >>/etc/xdg/kdeglobals

# Taskbar pills always float. Plasma drops a floating panel to the screen edge as a plain bar whenever a window
# touches it; the guide's pills never change shape. Fail the build if Plasma renamed this, instead of shipping bars.
PANEL=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml
sed -i 's|property bool touchingWindowDirect: visibleWindowsModel.count > 0|property bool touchingWindowDirect: false // OneUI OS: pills always float|' "$PANEL"
grep -q 'touchingWindowDirect: false' "$PANEL"

# Right pill stays as the guide draws it (bell, status, clock). Discover's update icon is redundant: the image and
# Flatpaks update themselves. Xwayland Video Bridge idles as a hidden tray item, which alone keeps the "^" overflow
# arrow on screen; X11-only apps lose screen sharing of Wayland windows (`xwaylandvideobridge` brings it back).
rm -f /etc/xdg/autostart/org.kde.discover.notifier.desktop /etc/xdg/autostart/org.kde.xwaylandvideobridge.desktop

# First boot follows the guide's order (Wi-Fi, account, look, Galaxy features, done): our "look" and "done" pages
# replace Fedora's dark-mode page and KDE's "Completed!" page, and Wi-Fi moves ahead of the account.
rm -rf /usr/share/plasma/packages/org.kde.plasmasetup.{prepare,finished}
sed -i 's/"X-KDE-Weight": 50/"X-KDE-Weight": 15/' /usr/share/plasma/packages/org.kde.plasmasetup.wifi/metadata.json

# Plasma Setup's welcome screen hardcodes wallpapers/Default/contents/images{,_dark}/3840x2160.jxl
# (Fedora's wallpaper); point it at ours. Qt sniffs the PNG despite the .jxl name (checked in a F44 VM).
for d in images images_dark; do
    for f in /usr/share/wallpapers/Default/contents/$d/3840x2160.*; do
        if [ -e "$f" ]; then ln -sf "/usr/share/wallpapers/OneUIOS/contents/$d/5120x2880.png" "$f"; fi
    done
done

### Branding. ID stays "fedora": bootc-image-builder and dnf resolve repos from it.
sed -i -e 's/^NAME=.*/NAME="OneUI OS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="OneUI OS 0.1 (Galaxy Book Edition)"/' \
    -e 's/^LOGO=.*/LOGO=oneui-os-logo/' /usr/lib/os-release
grep -q '^LOGO=' /usr/lib/os-release || echo 'LOGO=oneui-os-logo' >>/usr/lib/os-release

### Galaxy Book speakers (built in the kmod stage, see kmod.sh)
KVER=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)
cp -a /kmod/lib/modules/. /usr/lib/modules/
install -Dm755 /kmod/libexec/max98390-hda-i2c-setup /usr/libexec/max98390-hda-i2c-setup
depmod -a "$KVER"
# Lets galaxybook-setup queue the signing key without asking for a password (the user types "oneui-os" once in MokManager).
mokutil --generate-hash=oneui-os >/usr/share/oneui-os/mok.hash

### Services
systemctl enable plasma-setup.service power-profiles-daemon.service \
    galaxybook-setup.service max98390-hda-i2c-setup.service oneui-os-flatpaks.service
