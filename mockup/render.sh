#!/bin/sh
# Render every view × theme to renders/<view>-<theme>.png at 2880×1800 (1920×1200 logical @1.5x).
# --virtual-time-budget lets open animations finish before the screenshot.
cd "$(dirname "$0")"
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
URL="file:///$(pwd -W 2>/dev/null || pwd)/index.html"
for v in desktop finder drawer notifs overview; do
  for t in light dark; do
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --window-size=1920,1200 --force-device-scale-factor=1.5 --virtual-time-budget=3000 \
      --screenshot="$TEMP/gos.png" "$URL?theme=$t&view=$v" 2>/dev/null
    cp "$TEMP/gos.png" "renders/$v-$t.png" || echo "locked: renders/$v-$t.png"
  done
done
