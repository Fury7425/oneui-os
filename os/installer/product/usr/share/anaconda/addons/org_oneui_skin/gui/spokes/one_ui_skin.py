# One UI skin for the installer's GTK screens, from the OneUI OS Motion guide (mockup/motion.html, "First boot").
#
# Anaconda imports every module under /usr/share/anaconda/addons/*/gui/spokes/ while it collects spokes. This one
# defines no spoke; importing it only schedules a light check that restyles the screens as they appear, the same
# way Plasma Setup's Skin.qml does for first boot:
#  - the installer sits on the blurred wallpaper and each screen's content on one glass card (one-ui.css);
#  - the welcome screen opens with "Hello" in ten languages, as first boot does;
#  - installation progress becomes a ring with the percentage inside, the step text under it.
# Widgets are looked up by their Glade ids. If an Anaconda update renames them, nothing matches and the stock
# screen stays; any error here is logged and the skin gives up instead of breaking the installer.

import logging
import math

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import GLib, GObject, Gtk, Pango, PangoCairo

log = logging.getLogger("anaconda.oneui")

WORDS = ["Hello", "안녕하세요", "Bonjour", "Hola", "こんにちは", "Hallo", "Ciao", "你好", "Olá", "Merhaba"]
INK = (24 / 255, 24 / 255, 30 / 255)
BASE_WINDOWS = ("AnacondaHubWindow", "AnacondaSpokeWindow", "AnacondaStandaloneWindow")


def _animations():
    return Gtk.Settings.get_default().get_property("gtk-enable-animations")


def _walk(widget):
    yield widget
    if isinstance(widget, Gtk.Container):
        kids = []
        widget.forall(lambda c, acc: acc.append(c), kids)
        for c in kids:
            yield from _walk(c)


def _gid(widget):
    try:
        return Gtk.Buildable.get_name(widget) or ""
    except TypeError:
        return ""


class Ring(Gtk.DrawingArea):
    """Circular progress: ink arc on a 16% track, percentage in the middle. Spins a short arc until the first step
    lands, and eases toward each new value instead of jumping."""

    SIZE = 176
    WIDTH = 9

    def __init__(self, bar):
        super().__init__()
        self.bar = bar
        self.shown = 0.0
        self.angle = 0.0
        self.drawn = False
        self.set_size_request(self.SIZE, self.SIZE)
        self.set_halign(Gtk.Align.CENTER)
        self.set_margin_bottom(18)
        self.connect("draw", self.on_draw)
        self.add_tick_callback(self.on_tick)

    def on_tick(self, _widget, _clock):
        target = self.bar.get_fraction()
        if not _animations():
            self.shown = target
        elif abs(target - self.shown) > 0.0005:
            self.shown += (target - self.shown) * 0.12
        else:
            self.shown = target
        if self.shown <= 0.0005:
            self.angle = (self.angle + 0.09) % (2 * math.pi) if _animations() else 0.0
        self.queue_draw()
        return GLib.SOURCE_CONTINUE

    def on_draw(self, _widget, cr):
        try:
            w, h = self.get_allocated_width(), self.get_allocated_height()
            cx, cy, r = w / 2, h / 2, (min(w, h) - self.WIDTH) / 2 - 1
            cr.set_line_width(self.WIDTH)
            cr.set_line_cap(1)  # cairo.LINE_CAP_ROUND
            cr.set_source_rgba(*INK, 0.16)
            cr.arc(cx, cy, r, 0, 2 * math.pi)
            cr.stroke()

            cr.set_source_rgba(*INK, 1)
            top = -math.pi / 2
            if self.shown <= 0.0005:
                start = top + self.angle
                cr.arc(cx, cy, r, start, start + math.pi / 2)
                cr.stroke()
                text = ""
            else:
                cr.arc(cx, cy, r, top, top + 2 * math.pi * min(self.shown, 1.0))
                cr.stroke()
                text = "%d%%" % round(self.shown * 100)

            if text:
                layout = self.create_pango_layout(text)
                font = Pango.FontDescription.from_string("Pretendard Variable, Noto Sans Bold")
                font.set_weight(Pango.Weight.BOLD)
                font.set_absolute_size(34 * Pango.SCALE)
                layout.set_font_description(font)
                tw, th = layout.get_pixel_size()
                cr.move_to(cx - tw / 2, cy - th / 2)
                PangoCairo.show_layout(cr, layout)

            if not self.drawn:
                # the ring works, so the stock bar and spinner can go
                self.drawn = True
                GLib.idle_add(self.bar.hide)
        except Exception:  # pylint: disable=broad-except
            log.exception("One UI ring could not draw; keeping the progress bar")
            self.disconnect_by_func(self.on_draw)
            self.hide()
        return False


class Hello:
    """'Hello' in the ten languages of first boot; the word leaves on the Exit timing and the next fades in."""

    def __init__(self, label):
        self.label = label
        self.index = 0
        label.set_attributes(None)  # Glade's "Noto Sans Bold 16" would beat the stylesheet
        label.get_style_context().add_class("oneui-hello")
        label.set_text(WORDS[0])
        GLib.timeout_add(1900, self.next)

    def next(self):
        if not self.label.get_mapped():
            self.label.set_text(WORDS[self.index])  # Anaconda retranslates it on language change
            return GLib.SOURCE_CONTINUE
        if not _animations():
            self.index = (self.index + 1) % len(WORDS)
            self.label.set_text(WORDS[self.index])
            return GLib.SOURCE_CONTINUE
        self.fade(1.0, 0.0, 200, self.swap)
        return GLib.SOURCE_CONTINUE

    def swap(self):
        self.index = (self.index + 1) % len(WORDS)
        self.label.set_text(WORDS[self.index])
        self.fade(0.0, 1.0, 220, None)

    def fade(self, a, b, ms, then):
        steps = max(1, ms // 16)
        state = {"i": 0}

        def step():
            state["i"] += 1
            t = state["i"] / steps
            self.label.set_opacity(a + (b - a) * t)
            if state["i"] < steps:
                return GLib.SOURCE_CONTINUE
            if then:
                then()
            return GLib.SOURCE_REMOVE

        GLib.timeout_add(16, step)


def _skin_base_window(win):
    ctx = win.get_style_context()
    if ctx.has_class("oneui-skinned"):
        return
    ctx.add_class("oneui-skinned")

    area = win.get_action_area()
    if area is not None:
        area.get_style_context().add_class("oneui-card")

    ids = {}
    for w in _walk(win):
        gid = _gid(w)
        if gid:
            ids[gid] = w

    # Continue / Begin Installation / Reboot System: the ink pill, like first boot's Next (.su-next)
    if isinstance(ids.get("continueButton"), Gtk.Button):
        ids["continueButton"].get_style_context().add_class("suggested-action")

    if "welcomeLabel" in ids:
        Hello(ids["welcomeLabel"])
        pick = ids.get("pickLanguageLabel")
        if pick is not None:
            pick.set_attributes(None)
            pick.get_style_context().add_class("oneui-sub")

    bar, box, row = ids.get("progressBar"), ids.get("progressBox"), ids.get("box1")
    if bar is not None and box is not None:
        ring = Ring(bar)
        box.pack_start(ring, False, False, 0)
        box.reorder_child(ring, 0)
        box.set_halign(Gtk.Align.FILL)
        ring.show()
        spinner = ids.get("progressSpinner")
        if spinner is not None:
            spinner.set_no_show_all(True)
            spinner.hide()
        label = ids.get("progressLabel")
        if label is not None:
            label.set_halign(Gtk.Align.CENTER)
            label.set_justify(Gtk.Justification.CENTER)
            label.get_style_context().add_class("oneui-sub")
        if row is not None:
            row.set_halign(Gtk.Align.CENTER)


def _tick():
    try:
        for top in Gtk.Window.list_toplevels():
            # only Anaconda's main window; dialogs keep the plain look
            if type(top).__name__ != "MainWindow" or not top.get_visible():
                continue
            top.get_style_context().add_class("oneui-main")
            for w in _screens(top):
                _skin_base_window(w)
        return GLib.SOURCE_CONTINUE
    except Exception:  # pylint: disable=broad-except
        log.exception("One UI skin stopped")
        return GLib.SOURCE_REMOVE


def _screens(widget):
    """Anaconda's screens under the main window, without walking into them (that is the expensive part)."""
    if GObject.type_name(widget) in BASE_WINDOWS:
        yield widget
    elif isinstance(widget, Gtk.Container):
        kids = []
        widget.forall(lambda c, acc: acc.append(c), kids)
        for c in kids:
            yield from _screens(c)


# Screens join the main window as the installer reaches them; each one is skinned once.
GLib.timeout_add(250, _tick)
