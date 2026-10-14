// SPDX-License-Identifier: GPL-2.0-or-later
// OneUI OS popups, from the OneUI OS Motion guide ("Popups: fade the material, lift on the panel spring").
// Taskbar popups (quick panel, calendar, drawer, notifications list) and notification bubbles fade in over
// 180 ms while they rise 16 px and grow from 94 % on the panel spring (OutBack: a little overshoot). They leave
// in 200 ms on the Exit curve (InCubic), 10 px down to 97 %, with no bounce. Menus, tooltips and the rest only
// fade, the way KWin's Fading popups does. It replaces Sliding popups and Fading popups (both off in kwinrc),
// so no window is animated twice. Blur behind follows the window's opacity, so the glass fades as one piece.
"use strict";

var blacklist = [
    "ksmserver ksmserver",
    "ksmserver-logout-greeter ksmserver-logout-greeter",
    "kscreenlocker_greet kscreenlocker_greet",
    "ksplashqml ksplashqml",
];

function kind(w) {
    if (blacklist.indexOf(w.windowClass) != -1) {
        return null;
    }
    if (w.appletPopup || w.notification || w.criticalNotification) {
        return "panel";
    }
    if (w.tooltip) {
        return "tip";
    }
    if (w.popupWindow || w.outline || w.splash || w.toolbar || w.onScreenDisplay) {
        return "fade";
    }
    if (!w.managed && !w.utility) {
        return "fade";
    }
    return null;
}

var popups = {
    loadConfig: function () {
        popups.fadeIn = animationTime(180);
        popups.lift = animationTime(420);
        popups.out = animationTime(200);
        popups.tipIn = animationTime(260);
        popups.tipFade = animationTime(160);
        popups.tipOut = animationTime(120);
    },
    added: function (w) {
        if (effects.hasActiveFullScreenEffect || !w.visible) {
            return;
        }
        var k = kind(w);
        if (!k || !effect.grab(w, Effect.WindowAddedGrabRole)) {
            return;
        }
        if (k == "tip") {
            // guide tooltips: fade 160 ms and settle 6 px on the Enter curve (OutQuint is its closest stock curve)
            w.oneuiIn = animate({ window: w, duration: popups.tipIn, animations: [
                { type: Effect.Opacity, from: 0.0, to: 1.0, curve: QEasingCurve.Linear, duration: popups.tipFade },
                { type: Effect.Translation, from: { value1: 0, value2: 6 }, to: { value1: 0, value2: 0 }, curve: QEasingCurve.OutQuint }] });
            return;
        }
        var a = [{ type: Effect.Opacity, from: 0.0, to: 1.0, curve: QEasingCurve.Linear, duration: popups.fadeIn }];
        if (k == "panel") {
            a.push({ type: Effect.Scale, from: { value1: 0.94, value2: 0.94 }, to: { value1: 1.0, value2: 1.0 },
                     curve: QEasingCurve.OutBack, duration: popups.lift });
            a.push({ type: Effect.Translation, from: { value1: 0, value2: 16 }, to: { value1: 0, value2: 0 },
                     curve: QEasingCurve.OutBack, duration: popups.lift });
        }
        w.oneuiIn = animate({ window: w, duration: popups.lift, animations: a });
    },
    closed: function (w) {
        if (effects.hasActiveFullScreenEffect || !w.visible || w.skipsCloseAnimation) {
            return;
        }
        var k = kind(w);
        if (!k || !effect.grab(w, Effect.WindowClosedGrabRole)) {
            return;
        }
        var a = [{ type: Effect.Opacity, from: 1.0, to: 0.0 }];
        if (k == "panel") {
            a.push({ type: Effect.Scale, from: { value1: 1.0, value2: 1.0 }, to: { value1: 0.97, value2: 0.97 } });
            a.push({ type: Effect.Translation, from: { value1: 0, value2: 0 }, to: { value1: 0, value2: 10 } });
        }
        // tooltips leave at once: 120 ms, linear
        w.oneuiOut = animate({ window: w, duration: k == "tip" ? popups.tipOut : popups.out,
                               curve: k == "tip" ? QEasingCurve.Linear : QEasingCurve.InCubic, animations: a });
    },
    dataChanged: function (w, role) {
        // another effect took the window over: stop ours
        if (role == Effect.WindowAddedGrabRole && w.oneuiIn && effect.isGrabbed(w, role)) {
            cancel(w.oneuiIn);
            delete w.oneuiIn;
        } else if (role == Effect.WindowClosedGrabRole && w.oneuiOut && effect.isGrabbed(w, role)) {
            cancel(w.oneuiOut);
            delete w.oneuiOut;
        }
    },
    init: function () {
        popups.loadConfig();
        effect.configChanged.connect(popups.loadConfig);
        effects.windowAdded.connect(popups.added);
        effects.windowClosed.connect(popups.closed);
        effects.windowDataChanged.connect(popups.dataChanged);
    }
};

popups.init();
