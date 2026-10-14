#!/usr/bin/bash
# Titanoboa's post-rootfs hook: runs inside the live USB's root filesystem (a copy of the One UI image) before it is
# squashed. It turns the image into the installer: the One UI installer app opens on login, and first-boot setup
# waits for the installed system. build-iso.yml replaces @IMAGE_REF@ before handing this file to titanoboa.
set -euxo pipefail

# The installer app (/usr/libexec/oneui-installer) is Python + QML; PySide6 only ships on the USB, not in installs.
dnf5 -y install python3-pyside6

# The image the USB carries (titanoboa pulls it into /var/lib/containers/storage) and the one installs update from.
echo "@IMAGE_REF@" >/usr/share/oneui-os/image-ref

# Open the installer on login, and list it in the app menu so "Try it first" can come back to it.
sed -i 's/^NoDisplay=true/NoDisplay=false/' /usr/share/applications/oneui-installer.desktop
cp /usr/share/applications/oneui-installer.desktop /etc/xdg/autostart/oneui-installer.desktop

# First-boot setup is for the installed laptop, not the live session.
systemctl disable plasma-setup.service

# The live user starts the root helper without a password (the session itself has none).
cat >/etc/polkit-1/rules.d/50-oneui-installer.rules <<'EOF'
polkit.addRule(function (action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" && subject.user == "liveuser" && subject.local && subject.active &&
        action.lookup("program") == "/usr/libexec/oneui-installer/install-helper") {
        return polkit.Result.YES;
    }
});
EOF
