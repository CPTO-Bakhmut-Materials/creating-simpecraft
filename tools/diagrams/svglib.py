"""Minimal library for the course diagrams: writes SVG and checks that labels
do not overlap anything.

Drawing rules (after ISO 128 and ISO 3098):
- upright lettering, labels are horizontal only;
- text heights follow a √2 series: SM = 12, MD = 17, LG = 24 px;
- line widths relate as 1 : 2 : 4 (THIN, WIDE, XWIDE);
- leader lines are thin and end in a dot inside an area or an arrow on an
  object's outline;
- a label crosses no line, overlaps no other label and never straddles a
  shape's border: it is either fully inside or fully outside.

Fig.save() checks these rules and fails with a list of violations.
Text width is measured with DejaVu Sans (bundled with matplotlib) and written
to textLength, so a different browser font cannot make a label longer.
"""

import base64
import math
import os
from html import escape

import matplotlib
from PIL import ImageFont

# Text height series (ISO 3098: √2 steps).
SM, MD, LG = 12, 17, 24
# Line widths (ISO 128: 1 : 2 : 4).
THIN, WIDE, XWIDE = 1, 2, 4

INK = "#1f2933"
MUTED = "#6b7785"
GRID = "#d5dde8"
BLUE = "#2f6fdb"
GREEN = "#3a9a4e"
RED = "#d64545"
ORANGE = "#e8833a"
PURPLE = "#7e4fc4"
GRAY = "#7a8594"
YELLOW = "#d9a400"
STONE_C = "#7f7f7f"
DIRT_C = "#79553a"
GRASS_C = "#5f9f35"

# Light fills matching the colours above.
FILL = {
    BLUE: "#e3ebfa", GREEN: "#e4f1e6", RED: "#f9e3e3", ORANGE: "#fbece1",
    PURPLE: "#ede6f8", GRAY: "#eceef1", YELLOW: "#fbf1cf",
}

SANS = "DejaVu Sans, Verdana, Geneva, sans-serif"
MONO = "DejaVu Sans Mono, Consolas, Menlo, monospace"

_FONT_DIR = os.path.join(matplotlib.get_data_path(), "fonts", "ttf")
_FONT_FILES = {
    (False, "normal", "normal"): "DejaVuSans.ttf",
    (False, "bold", "normal"): "DejaVuSans-Bold.ttf",
    (False, "normal", "italic"): "DejaVuSans-Oblique.ttf",
    (False, "bold", "italic"): "DejaVuSans-BoldOblique.ttf",
    (True, "normal", "normal"): "DejaVuSansMono.ttf",
    (True, "bold", "normal"): "DejaVuSansMono-Bold.ttf",
}
_fonts = {}

PAD = 3  # minimum clearance around a label, px


def text_width(s, size, weight="normal", style="normal", mono=False):
    key = (mono, weight, style, size)
    if key not in _fonts:
        path = os.path.join(_FONT_DIR, _FONT_FILES[(mono, weight, style)])
        _fonts[key] = ImageFont.truetype(path, size * 4)
    return _fonts[key].getlength(s) / 4


def fmt(v):
    return f"{v:.1f}".rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


def _seg_hits_box(p, q, box):
    """Whether segment pq crosses the box (x0, y0, x1, y1) (Liang-Barsky)."""
    x0, y0, x1, y1 = box
    dx, dy = q[0] - p[0], q[1] - p[1]
    t0, t1 = 0.0, 1.0
    for pk, qk in ((-dx, p[0] - x0), (dx, x1 - p[0]), (-dy, p[1] - y0), (dy, y1 - p[1])):
        if pk == 0:
            if qk < 0:
                return False
        else:
            t = qk / pk
            if pk < 0:
                t0 = max(t0, t)
            else:
                t1 = min(t1, t)
            if t0 > t1:
                return False
    return True


def _boxes_hit(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def _inside(a, b):
    return a[0] >= b[0] and a[1] >= b[1] and a[2] <= b[2] and a[3] <= b[3]


def bezier(p0, p1, p2, p3, n=24):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        pts.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                    u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
    return pts


def arc_points(cx, cy, r, a0, a1, n=32, ry=None):
    """Arc points; angles in degrees, 0° points right, positive is counter-clockwise (up)."""
    ry = r if ry is None else ry
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy - ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


class Fig:
    def __init__(self, w, h, title):
        self.w, self.h, self.title = w, h, title
        self.out = []
        self.texts = []      # (box, label)
        self.edges = []      # (p, q, owner) — lines a label must not touch
        self.areas = []      # (box, owner) — shapes: a label is fully inside or fully outside
        self.solids = []     # (box, owner) — dots/markers: a label must not overlap them
        self.defs = []

    # --- primitives ------------------------------------------------------

    def _register_poly(self, pts, closed, check, owner):
        if not check:
            return
        n = len(pts) if closed else len(pts) - 1
        for i in range(n):
            self.edges.append((pts[i], pts[(i + 1) % len(pts)], owner))

    def rect(self, x, y, w, h, fill="none", stroke=None, sw=WIDE, rx=0, dash=None,
             check=True, opacity=None, owner=None):
        a = f'<rect x="{fmt(x)}" y="{fmt(y)}" width="{fmt(w)}" height="{fmt(h)}"'
        if rx:
            a += f' rx="{fmt(rx)}"'
        a += f' fill="{fill}"'
        if stroke:
            a += f' stroke="{stroke}" stroke-width="{fmt(sw)}"'
        if dash:
            a += f' stroke-dasharray="{dash}"'
        if opacity is not None:
            a += f' opacity="{opacity}"'
        self.out.append(a + "/>")
        if check:
            self.areas.append(((x, y, x + w, y + h), owner or "rect"))

    def poly(self, pts, fill="none", stroke=None, sw=WIDE, closed=True, dash=None,
             check=True, opacity=None, owner="poly", join="round", cap="round"):
        d = "M" + " L".join(f"{fmt(x)},{fmt(y)}" for x, y in pts) + (" Z" if closed else "")
        a = f'<path d="{d}" fill="{fill}"'
        if stroke:
            a += (f' stroke="{stroke}" stroke-width="{fmt(sw)}" stroke-linejoin="{join}"'
                  f' stroke-linecap="{cap}"')
        if dash:
            a += f' stroke-dasharray="{dash}"'
        if opacity is not None:
            a += f' opacity="{opacity}"'
        self.out.append(a + "/>")
        self._register_poly(pts, closed, check, owner)

    def line(self, x1, y1, x2, y2, stroke=INK, sw=THIN, dash=None, check=True, owner="line"):
        self.poly([(x1, y1), (x2, y2)], stroke=stroke, sw=sw, closed=False, dash=dash,
                  check=check, owner=owner, cap="butt")

    def circle(self, cx, cy, r, fill=INK, stroke=None, sw=THIN, check=True, owner="dot"):
        a = f'<circle cx="{fmt(cx)}" cy="{fmt(cy)}" r="{fmt(r)}" fill="{fill}"'
        if stroke:
            a += f' stroke="{stroke}" stroke-width="{fmt(sw)}"'
        self.out.append(a + "/>")
        if check:
            self.solids.append(((cx - r, cy - r, cx + r, cy + r), owner))

    def raw(self, s):
        self.out.append(s)

    def image(self, x, y, w, h, src, pixelated=True, check=True):
        """Raster image inside the SVG, embedded (an <img> SVG does not load external files).
        src is a PNG path or the PNG bytes themselves."""
        if isinstance(src, str):
            with open(src, "rb") as f:
                src = f.read()
        data = base64.b64encode(src).decode()
        style = ' style="image-rendering:pixelated"' if pixelated else ""
        self.out.append(f'<image x="{fmt(x)}" y="{fmt(y)}" width="{fmt(w)}" height="{fmt(h)}"'
                        f' preserveAspectRatio="none"{style} href="data:image/png;base64,{data}"/>')
        if check:
            self.areas.append(((x, y, x + w, y + h), "image"))

    # --- arrows and leader lines ----------------------------------------

    def _head(self, tip, frm, color, sw, size=None):
        L = size or max(9, 3.2 * sw + 4)
        ang = math.atan2(tip[1] - frm[1], tip[0] - frm[0])
        half = math.radians(22)
        p1 = (tip[0] - L * math.cos(ang - half), tip[1] - L * math.sin(ang - half))
        p2 = (tip[0] - L * math.cos(ang + half), tip[1] - L * math.sin(ang + half))
        self.poly([tip, p1, p2], fill=color, stroke=None, owner="arrowhead")
        return (tip[0] - 0.75 * L * math.cos(ang), tip[1] - 0.75 * L * math.sin(ang))

    def arrow(self, pts, color=INK, sw=WIDE, start=False, end=True, dash=None, head=None,
              check=True):
        """Polyline with an arrowhead at the end (and/or the start)."""
        pts = list(pts)
        if end:
            pts[-1] = self._head(pts[-1], pts[-2], color, sw, head)
        if start:
            pts[0] = self._head(pts[0], pts[1], color, sw, head)
        self.poly(pts, stroke=color, sw=sw, closed=False, dash=dash, check=check, owner="arrow",
                  cap="butt")

    def curve_arrow(self, p0, c1, c2, p3, color=INK, sw=WIDE, end=True, start=False, dash=None):
        pts = bezier(p0, c1, c2, p3)
        tip_from = pts[-3]
        q3 = self._head(p3, tip_from, color, sw) if end else p3
        q0 = self._head(p0, pts[2], color, sw) if start else p0
        d = f"M{fmt(q0[0])},{fmt(q0[1])} C{fmt(c1[0])},{fmt(c1[1])} {fmt(c2[0])},{fmt(c2[1])} {fmt(q3[0])},{fmt(q3[1])}"
        a = f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{fmt(sw)}"'
        if dash:
            a += f' stroke-dasharray="{dash}"'
        self.out.append(a + "/>")
        self._register_poly(pts, False, True, "curve")

    def leader(self, frm, to, color=INK, end="dot"):
        """ISO 128 leader line from a label to an object; end = 'dot' (inside an area),
        'arrow' (on an outline) or None."""
        if end == "arrow":
            self.arrow([frm, to], color=color, sw=THIN)
        else:
            self.line(frm[0], frm[1], to[0], to[1], stroke=color, sw=THIN, owner="leader")
            if end == "dot":
                self.out.append(f'<circle cx="{fmt(to[0])}" cy="{fmt(to[1])}" r="2.5" fill="{color}"/>')

    # --- text ------------------------------------------------------------

    def text(self, x, y, s, size=SM, color=INK, weight="normal", style="normal", mono=False,
             anchor="start", check=True, halo=None, lh=1.3):
        """A label; y is the baseline of the first line, '\\n' splits lines.
        Returns the bounding box (x0, y0, x1, y1)."""
        boxes = []
        # Lines of one label are not checked against each other: they form one group.
        self._group = getattr(self, "_group", 0) + 1
        for i, line in enumerate(s.split("\n")):
            yy = y + i * size * lh
            w = text_width(line, size, weight, style, mono)
            x0 = x - (w / 2 if anchor == "middle" else w if anchor == "end" else 0)
            box = (x0, yy - 0.78 * size, x0 + w, yy + 0.25 * size)
            boxes.append(box)
            a = f'<text x="{fmt(x)}" y="{fmt(yy)}" font-size="{size}"'
            if mono:
                a += f' font-family="{MONO}"'
            if weight != "normal":
                a += f' font-weight="{weight}"'
            if style != "normal":
                a += f' font-style="{style}"'
            if anchor != "start":
                a += f' text-anchor="{anchor}"'
            if color != INK:
                a += f' fill="{color}"'
            if halo:
                a += (f' stroke="{halo}" stroke-width="4" stroke-linejoin="round"'
                      ' paint-order="stroke"')
            if line.strip():
                a += f' textLength="{w:.1f}" lengthAdjust="spacingAndGlyphs"'
            self.out.append(a + f">{escape(line)}</text>")
            if check and line.strip():
                self.texts.append((box, line, self._group))
        return (min(b[0] for b in boxes), min(b[1] for b in boxes),
                max(b[2] for b in boxes), max(b[3] for b in boxes))

    # --- ready-made blocks ----------------------------------------------

    def box(self, x, y, w, h, title, sub=None, color=BLUE, title_mono=False, rx=8,
            title_size=MD, sub_size=SM, fill=None):
        """Rounded box with a centred title and caption."""
        self.rect(x, y, w, h, fill=fill or FILL.get(color, "#fff"), stroke=color, sw=WIDE, rx=rx)
        tl = title.split("\n")
        sl = sub.split("\n") if sub else []
        th = len(tl) * title_size * 1.3
        sh = len(sl) * sub_size * 1.3
        gap = 8 if sl else 0
        top = y + (h - th - sh - gap) / 2
        self.text(x + w / 2, top + title_size * 0.95, title, size=title_size, weight="bold",
                  anchor="middle", mono=title_mono)
        if sl:
            self.text(x + w / 2, top + th + gap + sub_size * 0.95, sub, size=sub_size,
                      anchor="middle", color=INK)

    # --- checks and output ----------------------------------------------

    def check(self):
        errs = []
        canvas = (0, 0, self.w, self.h)
        padded = [((b[0] - PAD, b[1] - PAD, b[2] + PAD, b[3] + PAD), s, g) for b, s, g in self.texts]
        for i, (b, s, g) in enumerate(padded):
            raw = self.texts[i][0]
            if not _inside(raw, canvas):
                errs.append(f"outside the canvas: {s!r} {tuple(round(v) for v in raw)}")
            for b2, s2, g2 in padded[i + 1:]:
                if g != g2 and _boxes_hit(b, b2):
                    errs.append(f"label overlaps label: {s!r} / {s2!r}")
            for p, q, owner in self.edges:
                if _seg_hits_box(p, q, b):
                    errs.append(f"line ({owner}) crosses label {s!r}")
                    break
            for box, owner in self.solids:
                if _boxes_hit(b, box):
                    errs.append(f"marker ({owner}) under label {s!r}")
                    break
            for box, owner in self.areas:
                if _boxes_hit(raw, box) and not _inside(raw, box):
                    errs.append(f"label {s!r} straddles a shape border ({owner})")
                    break
        return errs

    def svg(self):
        head = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}"'
                f' viewBox="0 0 {self.w} {self.h}" font-family="{SANS}" fill="{INK}"'
                f' role="img" aria-label="{escape(self.title)}">\n'
                f"<title>{escape(self.title)}</title>\n")
        if self.defs:
            head += "<defs>" + "".join(self.defs) + "</defs>\n"
        head += f'<rect width="{self.w}" height="{self.h}" fill="#ffffff"/>\n'
        return head + "\n".join(self.out) + "\n</svg>\n"

    def save(self, path):
        """Writes the SVG if the checks pass. DIAGRAMS_PREVIEW=1 also writes a diagram
        with violations, so you can look at what is wrong."""
        errs = self.check()
        if not errs or os.environ.get("DIAGRAMS_PREVIEW"):
            with open(path, "w", encoding="utf-8") as f:
                f.write(self.svg())
        if errs:
            raise SystemExit(f"{path}:\n  " + "\n  ".join(dict.fromkeys(errs)))
