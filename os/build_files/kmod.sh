#!/usr/bin/bash
# Builds the MAX98390 speaker-amp driver used by Galaxy Book4/5 Pro and Ultra for the base image's kernel.
# It is not upstream yet (thesofproject/linux PR #5616). Delete this script and the kmod stage once
# `modinfo snd-hda-scodec-max98390` works on a stock Fedora kernel.
set -ouex pipefail

FIX=9788e950da3df61fe994e1cb871153933a99c162 # Andycodeman/samsung-galaxy-book-linux-fixes @ 2026-10-12

V=$(rpm -q --qf '%{VERSION}' kernel-core)
R=$(rpm -q --qf '%{RELEASE}' kernel-core)
A=$(rpm -q --qf '%{ARCH}' kernel-core)
KVER="$V-$R.$A"

# The base pins its kernel, so the matching kernel-devel may already be gone from the repos; Koji keeps every build.
dnf5 -y install gcc make "kernel-devel-$KVER" ||
    dnf5 -y install gcc make "https://kojipkgs.fedoraproject.org/packages/kernel/$V/$R/$A/kernel-devel-$KVER.rpm"

mkdir -p /src /out
curl -fsSL "https://github.com/Andycodeman/samsung-galaxy-book-linux-fixes/archive/$FIX.tar.gz" | tar xz -C /src --strip-components=1
make -C /src/speaker-fix/src KVER="$KVER" KDIR="/usr/src/kernels/$KVER"

# Signed modules load with Secure Boot on, once the user enrolls mok.der (galaxybook-setup queues that).
for ko in /src/speaker-fix/src/*.ko; do
    if [ -s /run/secrets/mok_key ]; then
        "/usr/src/kernels/$KVER/scripts/sign-file" sha256 /run/secrets/mok_key /ctx/system_files/usr/share/oneui-os/mok.der "$ko"
    else
        echo "WARNING: no mok_key secret, $(basename "$ko") is unsigned and will not load with Secure Boot on"
    fi
    install -Dm644 "$ko" "/out/lib/modules/$KVER/extra/$(basename "$ko")"
done
install -Dm755 /src/speaker-fix/max98390-hda-i2c-setup.sh /out/libexec/max98390-hda-i2c-setup
