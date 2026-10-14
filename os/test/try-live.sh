#!/usr/bin/bash
# Applies the OneUI OS look to a running Fedora KDE live session (VM or USB stick). Changes vanish on reboot.
# In the live session's terminal:
#   udisksctl mount -b /dev/disk/by-label/ONEUIOS
#   bash /run/media/liveuser/ONEUIOS/test/try-live.sh
set -euo pipefail
OS=$(cd "$(dirname "$0")/.." && pwd)

# Same steps as build_files/build.sh, minus packaging and Galaxy Book hardware bits.
sudo cp -r --no-preserve=mode "$OS/system_files/." /
sudo dnf -y install papirus-icon-theme jetbrains-mono-fonts
curl -fsSLo /tmp/pretendard.zip https://github.com/orioncactus/pretendard/releases/download/v1.3.9/Pretendard-1.3.9.zip
echo "04be351a74d6bf7d60c480a3087e51d185485d35a52023142af1df19eb8c428a  /tmp/pretendard.zip" | sha256sum -c
sudo unzip -oj /tmp/pretendard.zip public/variable/PretendardVariable.ttf -d /usr/share/fonts/pretendard
sudo fc-cache -f
sudo sh -c 'cat /usr/share/color-schemes/OneUIOSLight.colors >> /etc/xdg/kdeglobals'
sudo chmod 755 /usr/libexec/oneui-os-firstlogin
sudo sed -i 's|property bool touchingWindowDirect: visibleWindowsModel.count > 0|property bool touchingWindowDirect: false // OneUI OS: pills always float|' \
    /usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml
sudo rm -f /etc/xdg/autostart/org.kde.discover.notifier.desktop /etc/xdg/autostart/org.kde.xwaylandvideobridge.desktop
sudo rm -rf /usr/share/plasma/packages/org.kde.plasmasetup.{prepare,finished}
sudo sed -i 's/"X-KDE-Weight": 50/"X-KDE-Weight": 15/' /usr/share/plasma/packages/org.kde.plasmasetup.wifi/metadata.json
LNF=/usr/share/plasma/look-and-feel
sudo cp -r $LNF/org.oneuios.light.desktop/contents/layouts $LNF/org.oneuios.dark.desktop/contents/
for d in images images_dark; do
    for f in /usr/share/wallpapers/Default/contents/$d/3840x2160.*; do
        if [ -e "$f" ]; then sudo ln -sf "/usr/share/wallpapers/OneUIOS/contents/$d/5120x2880.png" "$f"; fi
    done
done

# The live user already has a desktop, so apply theme + three-pill layout the way a first login would.
# Over ssh (installed test VM, before first boot) there is no desktop yet; Plasma Setup's new user gets it.
[ -n "${WAYLAND_DISPLAY:-}" ] || exit 0
plasma-apply-lookandfeel --apply org.oneuios.light.desktop --resetLayout

echo "Done. Log out and back in (no password) so every app picks up the font."
echo "Dark version: plasma-apply-lookandfeel --apply org.oneuios.dark.desktop"
