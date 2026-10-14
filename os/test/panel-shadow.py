# Bake the guide's pill shadow (box-shadow: 0 14px 36px -14px, oklch(0.32 0.04 300 / 0.3)) into Plasma panel shadow
# tiles. Like CSS, the shadow is cut away under the pill itself (the glass is translucent). Prints SVG elements.
import base64, io
from PIL import Image, ImageDraw, ImageFilter

R, PH, PW = 28, 56, 116                 # pill radius, height, sample width
T, B, S = 8, 40, 26                     # shadow reach: top, bottom, sides
W, H = S + PW + S, T + PH + B
SS = 4                                  # supersample for smooth edges
COLOR = (66, 56, 82)                    # oklch(0.32 0.04 300)

def rr(draw, box, r, fill):
    draw.rounded_rectangle([v * SS for v in box], radius=r * SS, fill=fill)

shape = Image.new("L", (W * SS, H * SS), 0)
rr(ImageDraw.Draw(shape), (S + 14, T + 28, S + PW - 14, T + PH + 14 - 14 + 0), 14, int(255 * 0.3))  # spread -14, y +14
shape = shape.filter(ImageFilter.GaussianBlur(18 * SS))
cut = Image.new("L", (W * SS, H * SS), 255)
rr(ImageDraw.Draw(cut), (S, T, S + PW, T + PH), R, 0)
alpha = Image.composite(shape, Image.new("L", shape.size, 0), cut).resize((W, H), Image.LANCZOS)
img = Image.new("RGBA", (W, H), COLOR + (0,))
img.putalpha(alpha)

def tile(name, box, x, y):
    t = img.crop(box)
    buf = io.BytesIO(); t.save(buf, "PNG", optimize=True)
    data = base64.b64encode(buf.getvalue()).decode()
    print(f'  <image id="{name}" x="{x}" y="{y}" width="{t.width}" height="{t.height}" xlink:href="data:image/png;base64,{data}"/>')

cw, th, bh = S + R, T + R, B + R
ox, oy = 0, 100                          # where the tiles sit in the SVG (outside the frame pieces)
tile("shadow-topleft", (0, 0, cw, th), ox, oy)
tile("shadow-top", (W // 2, 0, W // 2 + 1, T), ox + 60, oy)
tile("shadow-topright", (W - cw, 0, W, th), ox + 70, oy)
tile("shadow-left", (0, T + R, S, T + R + 1), ox + 130, oy)
tile("shadow-right", (W - S, T + R, W, T + R + 1), ox + 160, oy)
tile("shadow-bottomleft", (0, T + R, cw, H), ox, oy + 40)
tile("shadow-bottom", (W // 2, T + PH, W // 2 + 1, H), ox + 60, oy + 40)
tile("shadow-bottomright", (W - cw, T + R, W, H), ox + 70, oy + 40)
print(f'  <g fill="#ff00ff">\n'
      f'    <rect id="shadow-hint-top-margin" x="140" y="120" width="2" height="{T}"/>\n'
      f'    <rect id="shadow-hint-bottom-margin" x="144" y="120" width="2" height="{B}"/>\n'
      f'    <rect id="shadow-hint-left-margin" x="150" y="120" width="{S}" height="2"/>\n'
      f'    <rect id="shadow-hint-right-margin" x="150" y="124" width="{S}" height="2"/>\n  </g>')
