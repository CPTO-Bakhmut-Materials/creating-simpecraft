#!/usr/bin/env python3
"""Generates the lesson SVG diagrams into <lesson>/images/<name>.g.svg
(".g." marks a generated file: edit this script, not the SVG).

Usage: python3 tools/diagrams/build.py [name ...]
(no arguments builds every diagram). Needs matplotlib (only for its DejaVu
fonts, used to measure text) and Pillow.
DIAGRAMS_PREVIEW=1 also writes diagrams that fail the checks.
Diagram labels are Ukrainian on purpose: they appear in the book.
"""

import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from svglib import (BLUE, DIRT_C, FILL, GRASS_C, GRAY, GREEN, GRID, INK, LG, MD, MUTED, ORANGE,  # noqa: E402
                    PURPLE, RED, SM, STONE_C, THIN, WIDE, XWIDE, YELLOW, Fig, arc_points,
                    text_width)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TEXTURES = os.path.join(ROOT, "05-textures", "code", "assets", "textures")
DIAGRAMS = {}


def diagram(lesson, name):
    def wrap(fn):
        DIAGRAMS[name] = (lesson, fn)
        return fn
    return wrap


def norm(v):
    n = math.sqrt(sum(c * c for c in v))
    return tuple(c / n for c in v)


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def neg(v):
    return tuple(-c for c in v)


class Chart:
    """Cartesian chart frame: axes, ticks, grid."""

    def __init__(self, fig, x, y, w, h, xr, yr, xticks=(), yticks=(), xlabel=None, ylabel=None,
                 grid=True, ytick_labels=True, xfmt=str, yfmt=str):
        self.fig, self.x, self.y, self.w, self.h, self.xr, self.yr = fig, x, y, w, h, xr, yr
        if grid:
            for t in xticks:
                fig.line(self.px(t), y, self.px(t), y + h, stroke=GRID, check=False)
            for t in yticks:
                fig.line(x, self.py(t), x + w, self.py(t), stroke=GRID, check=False)
        fig.line(x, y + h, x + w, y + h, stroke=GRAY, owner="axis")
        fig.line(x, y, x, y + h, stroke=GRAY, owner="axis")
        for t in xticks:
            fig.line(self.px(t), y + h, self.px(t), y + h + 4, stroke=GRAY, check=False)
            fig.text(self.px(t), y + h + 24, xfmt(t), anchor="middle")
        for t in yticks:
            fig.line(x - 4, self.py(t), x, self.py(t), stroke=GRAY, check=False)
            if ytick_labels:
                fig.text(x - 8, self.py(t) + 4, yfmt(t), anchor="end")
        if xlabel:
            fig.text(x + w / 2, y + h + 46, xlabel, anchor="middle")
        if ylabel:
            # Labels are horizontal only (ISO 3098), so the y-axis caption sits above the axis.
            fig.text(x - 40, y - 24, ylabel)

    def px(self, v):
        return self.x + (v - self.xr[0]) / (self.xr[1] - self.xr[0]) * self.w

    def py(self, v):
        return self.y + self.h - (v - self.yr[0]) / (self.yr[1] - self.yr[0]) * self.h

    def pt(self, x, y):
        return (self.px(x), self.py(y))


# ---------------------------------------------------------------- 01-window

@diagram("01-window", "dt_comparison")
def dt_comparison():
    f = Fig(900, 430, "Рух без dt і з dt при різній частоті кадрів")
    styles = [(30, ORANGE, None), (60, BLUE, "9 5"), (144, RED, "2 4")]
    for i, (title, speed) in enumerate((("БЕЗ dt:  x = x + 5", None), ("З dt:  x = x + 300 · dt", 300))):
        ox = 70 + i * 450
        f.text(ox - 40, 28, title, size=MD, weight="bold")
        c = Chart(f, ox, 90, 330, 270, (0, 2), (0, 1500), xticks=(0, 0.5, 1, 1.5, 2),
                  yticks=range(0, 1501, 300), xlabel="час, с", ylabel="пройдено, пікселів",
                  xfmt=lambda t: f"{t:g}")
        for fps, color, dash in styles:
            v = 5 * fps if speed is None else speed
            f.poly([c.pt(0, 0), c.pt(2, 2 * v)], stroke=color, sw=WIDE if speed is None else 3,
                   closed=False, dash=dash if speed else None, owner=f"{fps} fps")
            if speed is None:
                f.text(c.px(2) + 8, c.py(2 * v) + 5, f"{fps} FPS", color=color, weight="bold")
        if speed is None:
            f.text(c.px(0.08), c.py(1380), "на швидкому моніторі гравець\n«біжить» майже в 5 разів швидше",
                   color=RED)
            f.leader((c.px(0.95), c.py(1180)), c.pt(1.3, 1.3 * 720), color=RED, end="dot")
        else:
            for k, (fps, color, dash) in enumerate(styles):
                y = c.py(1400) + k * 22
                f.line(c.px(0.08), y - 4, c.px(0.08) + 34, y - 4, stroke=color, sw=3, dash=dash)
                f.text(c.px(0.08) + 44, y, f"{fps} FPS", color=color, weight="bold")
            f.text(c.px(0.6), c.py(900), "усі три лінії збігаються", color=GREEN)
            f.leader((c.px(1.1), c.py(820)), c.pt(1.35, 405), color=GREEN, end="dot")
    f.save(out("dt_comparison"))


@diagram("01-window", "game_loop")
def game_loop():
    f = Fig(860, 430, "Ігровий цикл LÖVE")
    W, H = 200, 90
    load = (20, 30)
    events = (320, 30)
    update = (620, 160)
    draw = (320, 300)
    show = (20, 300)
    f.box(*load, W, H, "love.load()", "один раз на старті", GREEN, title_mono=True)
    f.box(*events, W, H, "події", "клавіші, миша →\nlove.keypressed …", PURPLE)
    f.box(*update, W, H, "love.update(dt)", "змінюємо стан гри", BLUE, title_mono=True)
    f.box(*draw, W, H, "love.draw()", "малюємо поточний стан", ORANGE, title_mono=True)
    f.box(*show, W, H, "показ кадру", "чекаємо vsync,\nміряємо dt", GRAY)
    f.arrow([(220, 75), (320, 75)])
    f.curve_arrow((520, 75), (600, 75), (700, 100), (720, 160))
    f.curve_arrow((720, 250), (700, 320), (600, 345), (520, 345))
    f.arrow([(320, 345), (220, 345)])
    f.curve_arrow((120, 300), (120, 200), (200, 140), (340, 120))
    f.text(30, 215, "наступний\nкадр", color=MUTED)
    f.text(420, 205, "ігровий цикл\n≈ 60 разів на секунду", size=MD, style="italic",
           color=MUTED, anchor="middle")
    f.save(out("game_loop"))


@diagram("01-window", "screen_coords")
def screen_coords():
    f = Fig(700, 430, "Система координат екрана LÖVE: квадрат уроку 1")
    sky = "#87bdf2"
    # The 1280×720 window at 0.43 scale: compact, so labels don't shrink in the book.
    S = 0.43
    ox, oy = 100, 76

    def P(x, y):
        return (ox + x * S, oy + y * S)

    f.text(20, 30, "Вікно 1280×720: де опиниться квадрат", size=MD, weight="bold")
    f.rect(ox, oy, 1280 * S, 720 * S, fill=sky, stroke=INK, sw=THIN)
    f.arrow([(ox, oy - 18), (ox + 110, oy - 18)], color=RED)
    f.text(ox + 118, oy - 13, "x", color=RED, weight="bold", size=MD)
    f.arrow([(ox - 18, oy), (ox - 18, oy + 110)], color=GREEN)
    f.text(ox - 18, oy + 132, "y", color=GREEN, weight="bold", size=MD, anchor="middle")
    f.circle(ox, oy, 4)
    f.text(ox - 28, oy + 5, "(0, 0)", anchor="end")
    f.circle(*P(1280, 720), 4)
    f.text(P(1280, 720)[0], P(1280, 720)[1] + 22, "(1280, 720)", anchor="end")
    # The 64×64 square at (100, 100), in the dirt colour from code/main.lua.
    sx, sy = P(100, 100)
    f.rect(sx, sy, 64 * S, 64 * S, fill="#78543b")
    f.circle(sx, sy, 3.5, fill=INK)
    f.text(sx + 6, sy + 64 * S + 30, "player = { x = 100, y = 100 }:\nлівий верхній кут квадрата",
           size=MD)
    f.leader((sx - 4, sy + 64 * S + 24), (sx - 1, sy + 3), end=None)
    # Where the keys move it.
    q = 64 * S
    cx, cy = sx + q / 2, sy + q / 2
    f.arrow([(cx, sy - 5), (cx, sy - 36)], color=GREEN, sw=WIDE)
    f.text(cx + 12, sy - 14, "W: y зменшується", color=GREEN, weight="bold", size=MD)
    f.arrow([(sx + q + 8, cy), (sx + q + 70, cy)], color=RED, sw=WIDE)
    f.text(sx + q + 78, cy + 6, "D: x збільшується", color=RED, weight="bold", size=MD)
    f.text(ox + 1280 * S / 2, oy + 720 * S - 30, "Чим більший y, тим нижче на екрані.",
           color="#165c25", size=MD, anchor="middle")
    f.save(out("screen_coords"))


# ---------------------------------------------------------------- 02-triangle

@diagram("02-triangle", "ndc")
def ndc():
    f = Fig(900, 440, "Координати екрана і нормалізовані координати пристрою (NDC)")
    sky = "#87bdf2"
    # Left: pixels, (0, 0) at the top left.
    f.text(30, 34, "Координати екрана (пікселі)", size=MD, weight="bold")
    x0, y0, w, h = 60, 110, 352, 198
    f.rect(x0, y0, w, h, fill=sky, stroke=INK, sw=THIN)
    f.arrow([(x0, y0 - 20), (x0 + 90, y0 - 20)], color=RED)
    f.text(x0 + 98, y0 - 15, "x", color=RED, weight="bold", size=MD)
    f.arrow([(x0 - 20, y0), (x0 - 20, y0 + 90)], color=GREEN)
    f.text(x0 - 25, y0 + 112, "y", color=GREEN, weight="bold", size=MD, anchor="middle")
    f.circle(x0, y0, 4)
    f.text(x0 - 26, y0 + 5, "(0, 0)", anchor="end")
    f.circle(x0 + w, y0 + h, 4)
    f.text(x0 + w, y0 + h + 22, "(1280, 720)", anchor="end")
    f.text(x0 + w / 2, y0 + h / 2 + 5, "y росте вниз", color="#165c25", size=MD, anchor="middle")
    # Right: NDC, (0, 0) in the centre, y up.
    f.text(455, 34, "Нормалізовані координати пристрою (NDC)", size=MD, weight="bold")
    cx, cy, s = 680, 235, 150

    def P(x, y):
        return (cx + x * s, cy - y * s)

    f.rect(cx - s, cy - s, 2 * s, 2 * s, fill=sky, stroke=INK, sw=THIN)
    f.arrow([(cx - s - 25, cy), (cx + s + 30, cy)], color=RED)
    f.text(cx + s + 36, cy + 6, "x", color=RED, weight="bold", size=MD)
    f.arrow([(cx, cy + s + 25), (cx, cy - s - 30)], color=GREEN)
    f.text(cx + 10, cy - s - 26, "y", color=GREEN, weight="bold", size=MD)
    for (x, y), anchor, dx in (((-1, 1), "end", -6), ((1, 1), "start", 6), ((-1, -1), "end", -6),
                               ((1, -1), "start", 6)):
        px, py = P(x, y)
        f.text(px + dx, py + (-6 if y > 0 else 16), f"({x}, {y})", color=MUTED, anchor=anchor)
    tri = [(-0.5, 0.4), (-0.8, -0.6), (-0.2, -0.6)]
    f.poly([P(*p) for p in tri], fill="#b59c8c", stroke=ORANGE, sw=WIDE)
    for (x, y), color in zip(tri, (BLUE, RED, GREEN)):
        f.circle(*P(x, y), 6, fill=color)
    f.text(P(-0.5, 0.4)[0], P(-0.5, 0.4)[1] - 14, "(-0.5, 0.4)", anchor="middle")
    # The bottom vertices are close together, so their labels go on two rows.
    f.text(P(-0.8, -0.6)[0] - 16, P(-0.8, -0.6)[1] + 26, "(-0.8, -0.6)")
    f.text(P(-0.2, -0.6)[0] + 22, P(-0.2, -0.6)[1] + 48, "(-0.2, -0.6)", anchor="end")
    f.text(P(0.5, 0.62)[0], P(0.5, 0.62)[1], "y росте вгору,\nрозмір вікна\nне важливий",
           color="#165c25", anchor="middle")
    f.save(out("ndc"))


@diagram("02-triangle", "pipeline")
def pipeline():
    f = Fig(900, 250, "Конвеєр рендерингу")
    steps = [("Вершини\n(Mesh)", "x, y, колір", GRAY),
             ("Вершинний\nшейдер", "де на екрані?\n(раз на вершину)", BLUE),
             ("Растеризація", "які пікселі\nпокриває △", PURPLE),
             ("Піксельний\nшейдер", "якого кольору?\n(раз на піксель)", ORANGE),
             ("Кадр", "на екрані", GREEN)]
    W, H, G, X0, Y0 = 150, 140, 30, 15, 20
    for i, (t, s, c) in enumerate(steps):
        f.box(X0 + i * (W + G), Y0, W, H, t, s, c)
        if i:
            f.arrow([(X0 + i * (W + G) - G, Y0 + H / 2), (X0 + i * (W + G), Y0 + H / 2)])
    cxs = [X0 + i * (W + G) + W / 2 for i in range(5)]
    f.text(cxs[1], Y0 + H + 30, "наш VERTEX_SHADER", color=BLUE, mono=True, anchor="middle")
    f.text(cxs[2], Y0 + H + 30, "робить відеокарта\nі змішує\nкольори вершин", color=PURPLE,
           anchor="middle")
    f.text(cxs[3], Y0 + H + 30, "поки що\nстандартний", color=ORANGE, anchor="middle")
    f.save(out("pipeline"))


@diagram("02-triangle", "quad_split")
def quad_split():
    f = Fig(860, 400, "Правильний і неправильний поділ квадрата на трикутники")
    f.defs.append('<pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse"'
                  ' patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="8"'
                  f' stroke="{RED}" stroke-width="1.2"/></pattern>')
    S = 220
    blue_f, orange_f, both_f = "#aac4f0", "#f6cdb0", "#c4a9a6"
    for k, (ox, title, color) in enumerate(((60, "Правильно: { 1, 2, 3,  1, 3, 4 }", GREEN),
                                            (500, "Помилка: { 1, 2, 3,  2, 3, 4 }", RED))):
        oy = 80
        v = {1: (ox, oy + S), 2: (ox + S, oy + S), 3: (ox + S, oy), 4: (ox, oy)}
        f.text(ox + S / 2, 34, title, size=MD, weight="bold", color=color, anchor="middle")
        if k == 0:
            f.poly([v[1], v[2], v[3]], fill=blue_f, stroke=BLUE, sw=WIDE)
            f.poly([v[1], v[3], v[4]], fill=orange_f, stroke=ORANGE, sw=WIDE)
            f.text(ox + S * 0.68, oy + S * 0.72, "△1", size=MD, weight="bold", color=BLUE, anchor="middle")
            f.text(ox + S * 0.32, oy + S * 0.36, "△2", size=MD, weight="bold", color=ORANGE, anchor="middle")
        else:
            c = (ox + S / 2, oy + S / 2)
            f.poly([v[1], c, v[4]], fill="url(#hatch)", stroke=RED, sw=WIDE)
            f.poly([v[1], v[2], c], fill=blue_f, stroke=BLUE, sw=WIDE)
            f.poly([v[4], c, v[3]], fill=orange_f, stroke=ORANGE, sw=WIDE)
            f.poly([c, v[2], v[3]], fill=both_f, stroke=INK, sw=THIN)
            f.text(ox + S / 2, oy + S * 0.86, "△1", size=MD, weight="bold", color=BLUE, anchor="middle")
            f.text(ox + S / 2, oy + S * 0.2, "△2", size=MD, weight="bold", color=ORANGE, anchor="middle")
            # Narrow regions are labelled outside, with a leader line (ISO 128).
            f.text(ox - 24, oy + S / 2 - 4, "дірка:\nтут порожньо", color=RED, weight="bold",
                   anchor="end")
            f.leader((ox - 20, oy + S / 2), (ox + S * 0.18, oy + S * 0.5), color=RED)
            f.text(ox + S + 24, oy + S / 2 - 4, "△1 і △2\nнакладаються", color=PURPLE, weight="bold")
            f.leader((ox + S + 20, oy + S / 2), (ox + S * 0.82, oy + S * 0.5), color=PURPLE)
        for n, (x, y) in v.items():
            f.circle(x, y, 5)
            dx = -14 if n in (1, 4) else 14
            dy = 22 if n in (1, 2) else -10
            f.text(x + dx, y + dy, str(n), size=MD, weight="bold", anchor="middle")
    f.save(out("quad_split"))


# ---------------------------------------------------------------- 03-perspective

def projector(ox, oy, s, ex=(1.0, 0.32), ey=(0.62, -0.42), ez=(0.0, -1.0)):
    """Oblique (cabinet) projection with world Z up."""
    def P(v):
        x, y, z = v
        return (ox + s * (x * ex[0] + y * ey[0] + z * ez[0]),
                oy + s * (x * ex[1] + y * ey[1] + z * ez[1]))
    return P


@diagram("03-perspective", "camera_basis")
def camera_basis():
    f = Fig(720, 470, "Осі світу і базис камери в Mat4.lookAlong")
    f.text(360, 30, "Базис камери в Mat4.lookAlong", size=MD, weight="bold", anchor="middle")
    P = projector(330, 300, 150)
    o = P((0, 0, 0))
    for v, name, dx, dy, anchor in (((1.25, 0, 0), "X", 8, 6, "start"), ((0, 1.35, 0), "Y", 8, 0, "start"),
                                    ((0, 0, 1.3), "Z (вгору)", 0, -10, "middle")):
        f.arrow([o, P(v)], color=GRAY, sw=THIN)
        p = P(v)
        f.text(p[0] + dx, p[1] + dy, name, color=GRAY, weight="bold", anchor=anchor)
    d = norm((0.7, 0.7, 0.25))
    z = neg(d)
    x = norm(cross((0, 0, 1), z))
    y = cross(z, x)
    L = 0.95
    for v, color in ((d, BLUE), (z, PURPLE), (x, RED), (y, GREEN)):
        f.arrow([o, P(tuple(c * L for c in v))], color=color, sw=3)
    f.circle(*o, 5, fill=RED)
    pd, pz, px, py = (P(tuple(c * L for c in v)) for v in (d, z, x, y))
    f.text(pd[0] + 10, pd[1] - 8, "direction", color=BLUE, weight="bold")
    f.text(pz[0] - 10, pz[1] + 22, "zAxis = −direction", color=PURPLE, weight="bold", anchor="end")
    f.text(px[0] + 6, px[1] + 26, "xAxis = up × zAxis\n(праворуч)", color=RED, weight="bold")
    f.text(py[0] - 14, py[1] - 4, "yAxis = zAxis × xAxis\n(вгору для камери)", color=GREEN,
           weight="bold", anchor="end")
    f.text(20, 455, "Камера в початку координат; up = (0, 0, 1) — вісь Z світу.", color=MUTED)
    f.save(out("camera_basis"))


@diagram("03-perspective", "frustum")
def frustum():
    f = Fig(660, 500, "Піраміда видимості (frustum)")
    f.text(330, 30, "Піраміда видимості (frustum)", size=MD, weight="bold", anchor="middle")

    # Camera coordinates: d is depth (to the right), h is sideways (towards the viewer), v is up.
    def P(d, h, v):
        return (70 + d * 1.0 + h * 0.5, 290 - v * 1.0 + h * 0.32)

    t, aspect, near, far = 0.38, 1.3, 60, 330

    def plane(dd):
        hv, hh = dd * t, dd * t * aspect
        return [P(dd, -hh, hv), P(dd, -hh, -hv), P(dd, hh, -hv), P(dd, hh, hv)]

    def cube(d, h, v, s, fill, top, side):
        # Faces visible in this projection: −d (left), +h (towards the viewer), +v (top).
        c = [[[P(d + i * s, h + j * s, v + k * s) for k in (0, 1)] for j in (0, 1)] for i in (0, 1)]
        f.poly([c[0][0][0], c[0][1][0], c[0][1][1], c[0][0][1]], fill=side, stroke=INK, sw=THIN)
        f.poly([c[0][1][0], c[1][1][0], c[1][1][1], c[0][1][1]], fill=fill, stroke=INK, sw=THIN)
        f.poly([c[0][0][1], c[0][1][1], c[1][1][1], c[1][0][1]], fill=top, stroke=INK, sw=THIN)

    gray = ("#b8b8b8", "#d6d6d6", "#9a9a9a")
    cam = P(0, 0, 0)
    far_pts, near_pts = plane(far), plane(near)
    cube(400, -30, -10, 36, *gray)          # beyond far: drawn before the far plane, since it is behind it
    f.poly(far_pts, fill="#fbe7d7", stroke=ORANGE, sw=THIN, opacity=0.75)
    for p in far_pts:
        f.line(cam[0], cam[1], p[0], p[1], stroke=INK, sw=THIN, owner="frustum edge")
    cube(170, -10, -20, 36, "#3a9a4e", "#62b874", "#2c7a3c")    # visible
    f.poly(near_pts, fill="#a9c3f0", stroke=BLUE, sw=WIDE, opacity=0.9)
    cube(120, -30, 110, 30, *gray)          # outside the frustum
    f.circle(*cam, 7, fill=RED)
    f.text(cam[0], cam[1] + 30, "камера", color=RED, weight="bold", anchor="middle")
    f.text(130, 352, "near", color=BLUE, weight="bold", anchor="middle")
    f.leader((130, 337), (130, 314), color=BLUE, end="arrow")
    f.text(328, 100, "far", color=ORANGE, weight="bold")
    f.text(250, 410, "видно", color=GREEN, weight="bold", anchor="middle")
    f.leader((250, 396), P(188, 8, -2), color=GREEN, end="dot")
    f.text(190, 112, "поза пірамідою —\nвідкинуто", color=GRAY, weight="bold", anchor="middle")
    f.text(522, 268, "далі за far —\nвідкинуто", color=GRAY, weight="bold")
    f.save(out("frustum"))


@diagram("03-perspective", "perspective_side")
def perspective_side():
    f = Fig(720, 450, "Перспектива з подібних трикутників")
    U = 60
    ex, ey = 120, 230

    def P(z, y):
        return (ex + z * U, ey - y * U)

    tan = math.tan(math.radians(35))
    zmax = 3.0
    for sgn in (1, -1):
        p = P(zmax, sgn * tan * zmax)
        f.line(ex, ey, p[0], p[1], stroke=GRAY, sw=THIN, dash="6 4", owner="fov")
    f.arrow([(ex, ey), (P(9.3, 0)[0], ey)], color=GRAY, sw=THIN)
    f.text(P(9.3, 0)[0] + 6, ey + 5, "z", color=GRAY, weight="bold")
    f.text(P(9.3, 0)[0] - 10, ey + 24, "глибина", color=GRAY, anchor="end")
    # The fovY arc sits beyond the screen, so its label has room between the rays.
    f.poly(arc_points(ex, ey, 150, -35, 35), stroke=PURPLE, sw=WIDE, closed=False, owner="fov arc")
    f.text(ex + 152, ey + 66, "fovY = 70°", color=PURPLE, weight="bold")
    # The screen at distance d = 1; its label sits outside the frustum, with a leader arrow.
    f.line(P(1, tan)[0], P(1, tan)[1], P(1, -tan)[0], P(1, -tan)[1], stroke=BLUE, sw=XWIDE, owner="screen")
    f.text(P(1, 0)[0] - 4, ey + 76, "екран (d = 1)", color=BLUE, weight="bold", anchor="end")
    f.leader((P(1, 0)[0] - 2, ey + 62), (P(1, 0)[0], P(1, -tan)[1] + 2), color=BLUE, end="arrow")
    for z, color in ((4, GREEN), (8, ORANGE)):
        b, t = P(z, 0), P(z, 2.4)
        f.line(b[0], b[1], t[0], t[1], stroke=color, sw=8, owner="object")
        f.line(ex, ey, t[0], t[1], stroke=color, sw=THIN, owner="ray")
        s = P(1, 2.4 / z)
        f.circle(*s, 5, fill=color)
        f.text(t[0] + 10, t[1] + 14, f"висота 2.4\nz = {z}", color=color)
    f.circle(ex, ey, 7, fill=RED)
    f.text(ex - 12, ey + 5, "око", color=RED, weight="bold", anchor="end")
    f.text(40, 60, "на екрані: y′ = y · d / z", size=MD, weight="bold")
    f.leader((P(1, 0)[0], 68), P(1, 0.6 + 0.12), end="arrow")
    f.text(360, 400, "Удвічі далі → удвічі менше на екрані. Тому матриця перспективи кладе z у w,\n"
           "а відеокарта потім ділить x, y, z на w («перспективне ділення»).", anchor="middle")
    f.save(out("perspective_side"))


@diagram("03-perspective", "transform_chain")
def transform_chain():
    f = Fig(900, 290, "Ланцюжок перетворень вершини")
    steps = [("Світ", "координати\nблоків", GREEN),
             ("Простір\nкамери", "камера в (0,0,0),\nдивиться на −Z", BLUE),
             ("Простір\nвідсікання", "(x, y, z, w)\nclip space", PURPLE),
             ("NDC", "−1..1 по x, y, z", ORANGE),
             ("Екран", "пікселі", GRAY)]
    ops = ["view\n(lookAlong)", "projection\n(perspective)", "÷ w\n(відеокарта)", "вікно\n(відеокарта)"]
    W, H, G, X0, Y0 = 150, 130, 30, 15, 20
    for i, (t, s, c) in enumerate(steps):
        f.box(X0 + i * (W + G), Y0, W, H, t, s, c)
        if i:
            gx = X0 + i * (W + G) - G
            f.arrow([(gx, Y0 + H / 2), (gx + G, Y0 + H / 2)])
            f.text(gx + G / 2, Y0 + H + 26, ops[i - 1], mono=True, anchor="middle", color=MUTED)
    f.rect(X0, 228, 5 * W + 4 * G, 40, fill=FILL[YELLOW], stroke=YELLOW, sw=THIN, rx=4)
    f.text(450, 253, "у шейдері:  viewProjection * vertexPosition,  де viewProjection = projection * view",
           mono=True, anchor="middle")
    f.save(out("transform_chain"))


# ---------------------------------------------------------------- 04-camera

@diagram("04-camera", "diagonal")
def diagonal():
    f = Fig(860, 300, "Діагональний рух з нормалізацією і без")
    U = 150
    panels = ((40, "Без нормалізації: (1, 0) + (0, 1)", RED, math.sqrt(2)),
              (470, "Нормалізовано: velocity / |velocity|", GREEN, 1.0))
    for ox, title, color, length in panels:
        f.text(ox, 30, title, size=MD, weight="bold", color=color)
        o = (ox + 40, 240)
        f.poly(arc_points(*o, U, -8, 98), stroke=GRID, sw=WIDE, closed=False, dash="5 5",
               check=False)
        f.arrow([o, (o[0], o[1] - U)], color=ORANGE, sw=WIDE)
        f.text(o[0] - 10, o[1] - U + 6, "W", color=ORANGE, weight="bold", size=MD, anchor="end")
        f.arrow([o, (o[0] + U, o[1])], color=BLUE, sw=WIDE)
        f.text(o[0] + U + 10, o[1] + 6, "D", color=BLUE, weight="bold", size=MD)
        r = length * U / math.sqrt(2)
        tip = (o[0] + r, o[1] - r)
        f.arrow([o, tip], color=color, sw=3)
        f.text(tip[0] + 12, tip[1] - 2, f"W + D\nдовжина {length:.2f}", color=color, weight="bold")
    f.text(40, 285, "Пунктир — коло радіусом 1: швидкість, з якою камера рухається по прямій.",
           color=MUTED)
    f.save(out("diagonal"))


@diagram("04-camera", "yaw_pitch")
def yaw_pitch():
    f = Fig(760, 560, "Від кутів yaw і pitch до напрямку погляду")
    f.text(380, 30, "Від кутів до напрямку погляду", size=MD, weight="bold", anchor="middle")
    # View "from the X side": X towards the viewer (down-left), Y right, Z up,
    # so the forward vector doesn't coincide with any axis on the drawing.
    P = projector(300, 330, 300, ex=(-0.55, 0.40), ey=(1.0, 0.12))
    o = P((0, 0, 0))
    f.poly([P((math.cos(a), math.sin(a), 0)) for a in
            (math.radians(d) for d in range(0, 101, 5))], stroke=GRID, sw=THIN, closed=False,
           check=False)
    for v, name, dx, dy, anchor in (((0.9, 0, 0), "X", -8, 14, "end"),
                                    ((0, 1.2, 0), "Y", 10, 6, "start"),
                                    ((0, 0, 0.85), "Z", 0, -10, "middle")):
        p = P(v)
        f.arrow([o, p], color=GRAY, sw=THIN)
        f.text(p[0] + dx, p[1] + dy, name, color=GRAY, weight="bold", size=MD, anchor=anchor)
    yaw, pitch = math.radians(55), math.radians(30)
    shadow = (math.cos(pitch) * math.cos(yaw), math.cos(pitch) * math.sin(yaw), 0)
    fwd = (shadow[0], shadow[1], math.sin(pitch))
    f.poly([o, P(shadow)], stroke=ORANGE, sw=WIDE, closed=False, dash="7 5", owner="cos(pitch)")
    f.poly([P(shadow), P(fwd)], stroke=GREEN, sw=WIDE, closed=False, dash="2 4", owner="sin(pitch)")
    # The yaw arc lies on the ground from +X to the "shadow"; the pitch arc is in the vertical plane.
    r = 0.3
    f.poly([P((r * math.cos(a), r * math.sin(a), 0)) for a in
            (yaw * i / 24 for i in range(25))], stroke=ORANGE, sw=3, closed=False, owner="yaw arc")
    r = 0.45
    f.poly([P((r * math.cos(b) * math.cos(yaw), r * math.cos(b) * math.sin(yaw), r * math.sin(b)))
            for b in (pitch * i / 24 for i in range(25))], stroke=GREEN, sw=3, closed=False,
           owner="pitch arc")
    f.arrow([o, P(fwd)], color=BLUE, sw=XWIDE)
    pf, ps = P(fwd), P(shadow)
    f.text(pf[0] + 12, pf[1] - 4, "forward()", color=BLUE, weight="bold", size=MD)
    f.text(ps[0] + 12, pf[1] + 40, "sin(pitch)", color=GREEN)
    f.text(ps[0] + 12, ps[1] + 18, "cos(pitch)", color=ORANGE)
    ya = P((0.3 * math.cos(yaw / 2), 0.3 * math.sin(yaw / 2), 0))
    f.text(ya[0] + 10, ya[1] + 60, "yaw", color=ORANGE, weight="bold", size=MD)
    f.leader((ya[0] + 8, ya[1] + 40), ya, color=ORANGE)
    # "pitch" goes in the free wedge between forward and the Y axis, next to its arc.
    pa = P((0.45 * math.cos(pitch) * math.cos(yaw), 0.45 * math.cos(pitch) * math.sin(yaw),
            0.45 * math.sin(pitch)))
    f.text(pa[0] + 12, pa[1] + 30, "pitch", color=GREEN, weight="bold", size=MD)
    f.text(380, 535, "forward = ( cos(pitch)·cos(yaw),  cos(pitch)·sin(yaw),  sin(pitch) )",
           mono=True, weight="bold", anchor="middle")
    f.save(out("yaw_pitch"))


# ---------------------------------------------------------------- 05-textures

def png_bytes(img):
    import io
    buf = io.BytesIO()
    img.save(buf, "PNG", optimize=True)
    return buf.getvalue()


@diagram("05-textures", "array_layers")
def array_layers():
    f = Fig(860, 470, "Шари масиву текстур ArrayImage")
    f.text(430, 30, "ArrayImage — одна текстура з кількома шарами", size=MD, weight="bold",
           anchor="middle")
    rows = (("GRASS", GRASS_C, ["top → шар 2", "side → шар 3", "bottom → шар 1"]),
            ("DIRT", DIRT_C, ["top/side/bottom → шар 1"]),
            ("STONE", STONE_C, ["top/side/bottom → шар 0"]))
    y = 70
    for name, color, maps in rows:
        f.rect(20, y, 100, 40, fill=color, rx=4)
        f.text(70, y + 26, name, size=MD, weight="bold", color="#ffffff", anchor="middle")
        for k, m in enumerate(maps):
            f.text(136, y + 25 + k * 26, m, mono=True)
        y += 26 * len(maps) + 34
    files = ["stone.png", "dirt.png", "grass_top.png", "dirt_grass.png"]
    S, DX, DY, X0, Y0 = 130, 34, 62, 620, 300
    for k in reversed(range(4)):
        x, yk = X0 + k * DX, Y0 - k * DY
        f.image(x, yk, S, S, os.path.join(TEXTURES, files[k]), check=False)
        f.rect(x, yk, S, S, stroke=INK, sw=THIN, check=False)
    # Layer labels sit left of the stack; each leader goes to the layer's visible top strip,
    # so it crosses no other layer (all layers in front of it lie lower).
    for k in range(4):
        x, yk = X0 + k * DX, Y0 - k * DY
        ly = yk + 22
        f.text(560, ly + 4, f"шар {k}: {files[k]}", mono=True, weight="bold", anchor="end")
        f.line(564, ly, x + 14, ly, stroke=INK, sw=THIN, owner="leader")
        f.circle(x + 14, ly, 3, check=False)
    f.text(20, 445, "Номер шару — третя текстурна координата вершини: (u, v, layer).\n"
           "Lua-таблиця TEXTURES починається з 1, а шари — з 0, тому layer = index − 1.")
    f.save(out("array_layers"))


@diagram("05-textures", "mipmaps_filters")
def mipmaps_filters():
    from PIL import Image
    f = Fig(900, 420, "Мипмапи і фільтри збільшення")
    f.text(20, 30, "Мипмапи: заздалегідь зменшені копії текстури", size=MD, weight="bold")
    base = Image.open(os.path.join(TEXTURES, "grass_top.png")).convert("RGB")
    x, bottom = 20, 300
    for size in (128, 64, 32, 16, 8, 4):
        img = base.resize((size, size), Image.BOX)
        f.image(x, bottom - size, size, size, png_bytes(img))
        f.rect(x, bottom - size, size, size, stroke=GRAY, sw=THIN, check=False)
        f.text(x + size / 2, bottom + 22, f"{size}×{size}", weight="bold", anchor="middle")
        x += max(size, 44) + 20
    f.text(20, 355, "Далекий блок займає кілька пікселів — відеокарта бере маленьку\n"
           "копію замість того, щоб вибирати випадкові пікселі з великої\n"
           "(інакше далечінь «мерехтить»).")
    f.text(520, 30, "Збільшення: 16×16 пікселів зблизька", size=MD, weight="bold")
    crop = Image.open(os.path.join(TEXTURES, "dirt_grass.png")).convert("RGB").crop((4, 24, 20, 40))
    data = png_bytes(crop)
    for k, (mode, color) in enumerate((("nearest", GREEN), ("linear", ORANGE))):
        cx = 520 + k * 190
        f.text(cx + 85, 82, f"збільшення «{mode}»", color=color, weight="bold", anchor="middle")
        f.image(cx, 96, 170, 170, data, pixelated=(mode == "nearest"))
        f.rect(cx, 96, 170, 170, stroke=GRAY, sw=THIN, check=False)
    f.text(520, 300, "У грі: setFilter(\"linear\", \"nearest\") —\nзменшення плавне, збільшення чітке.",
           mono=False)
    f.save(out("mipmaps_filters"))


@diagram("05-textures", "uv_mapping")
def uv_mapping():
    f = Fig(880, 470, "UV-координати текстури і кути грані")
    f.text(20, 30, "Текстура dirt_grass.png у координатах UV", size=MD, weight="bold")
    X, Y, S = 90, 110, 280
    f.image(X, Y, S, S, os.path.join(TEXTURES, "dirt_grass.png"))
    f.arrow([(X, 70), (X + S + 34, 70)], color=RED)
    f.text(X + S + 42, 76, "u", color=RED, weight="bold", size=MD)
    f.arrow([(50, Y), (50, Y + S + 34)], color=GREEN)
    f.text(50, Y + S + 58, "v", color=GREEN, weight="bold", size=MD, anchor="middle")
    for t in (0, 0.5, 1):
        f.line(X + t * S, 66, X + t * S, 74, stroke=RED, check=False)
        f.text(X + t * S, 58, f"{t:g}", anchor="middle", color=RED)
        f.line(46, Y + t * S, 54, Y + t * S, stroke=GREEN, check=False)
        f.text(40, Y + t * S + 4, f"{t:g}", anchor="end", color=GREEN)
    corners = {4: (0, 0), 3: (1, 0), 1: (0, 1), 2: (1, 1)}
    for n, (u, v) in corners.items():
        px, py = X + u * S, Y + v * S
        f.circle(px, py, 6)
        label = f"{n}: ({u}, {v})"
        w = text_width(label, SM, "bold")
        lx = px + 12 if u == 0 else px - 12 - w
        ly = py + 12 if v == 0 else py - 32
        f.rect(lx - 5, ly, w + 10, 22, fill="#1f2933", rx=3, opacity=0.85)
        f.text(lx, ly + 16, label, color="#ffffff", weight="bold")
    # Right: the +X face and its corners from the FACES table.
    f.text(500, 30, "Грань +X: кути з таблиці FACES", size=MD, weight="bold")
    FX, FY, FS = 590, 130, 200
    f.image(FX, FY, FS, FS, os.path.join(TEXTURES, "dirt_grass.png"))
    f.rect(FX, FY, FS, FS, stroke=INK, sw=WIDE, check=False)
    pos = {1: ("(1, 0, 0)", FX, FY + FS), 2: ("(1, 1, 0)", FX + FS, FY + FS),
           3: ("(1, 1, 1)", FX + FS, FY), 4: ("(1, 0, 1)", FX, FY)}
    for n, (coord, px, py) in pos.items():
        f.circle(px, py, 6)
        right = n in (2, 3)
        f.text(px + (12 if right else -12), py + (26 if n in (1, 2) else -14), f"{n}  {coord}",
               weight="bold", anchor="start" if right else "end")
    m = 34
    f.arrow([(FX + m, FY + FS - m), (FX + FS - m, FY + FS - m)], color="#ffffff", sw=3)
    f.arrow([(FX + FS - m, FY + FS - m), (FX + FS - m, FY + m)], color="#ffffff", sw=3)
    f.arrow([(FX + FS - m, FY + m), (FX + m, FY + m)], color="#ffffff", sw=3)
    f.text(FX + FS / 2, FY + FS + 66, "обхід 1→2→3→4 проти годинникової стрілки (ззовні);\n"
           "кут 1 — лівий нижній ⇒ UV (0, 1)", anchor="middle")
    f.save(out("uv_mapping"))


# ---------------------------------------------------------------- 06-world

@diagram("06-world", "flat_index")
def flat_index():
    f = Fig(860, 700, "Плоский індекс тривимірної сітки")
    f.text(430, 32, "index = x + sizeX · (y + sizeY · z)", size=MD, weight="bold", mono=True,
           anchor="middle")
    C, SX, SY = 60, 4, 3
    blue_f, orange_f = "#a9c3f0", "#f6cdb0"
    for z, (ox, color, fill) in enumerate(((70, BLUE, blue_f), (500, ORANGE, orange_f))):
        oy = 90
        f.text(ox + SX * C / 2, oy, f"шар z = {z}", weight="bold", color=color, size=MD, anchor="middle")
        top = oy + 16
        for y in range(SY):
            for x in range(SX):
                cx, cy = ox + x * C, top + (SY - 1 - y) * C
                f.rect(cx + 2, cy + 2, C - 4, C - 4, fill=fill, rx=2)
                f.text(cx + C / 2, cy + 27, str(x + SX * (y + SY * z)), size=MD, weight="bold",
                       anchor="middle")
                f.text(cx + C / 2, cy + 47, f"{x},{y},{z}", anchor="middle")
        f.arrow([(ox, top + SY * C + 14), (ox + SX * C + 20, top + SY * C + 14)], color=RED)
        f.text(ox + SX * C + 28, top + SY * C + 19, "x", color=RED, weight="bold", size=MD)
        f.arrow([(ox - 14, top + SY * C), (ox - 14, top - 10)], color=GREEN)
        f.text(ox - 14, top - 18, "y", color=GREEN, weight="bold", size=MD, anchor="middle")
    f.text(430, 196, "+1 по z →", color=PURPLE, weight="bold", size=MD, anchor="middle")
    # The same in memory: one flat array.
    oy = 330
    f.text(20, oy, "У пам'яті — один масив blocks[ ]:", weight="bold", size=MD)
    CW = 66
    for z, (color, fill) in enumerate(((BLUE, blue_f), (ORANGE, orange_f))):
        ry = oy + 20 + z * 60
        for i in range(12):
            idx = i + 12 * z
            x, rem = idx % SX, idx // SX
            y = rem % SY
            cx = 34 + i * CW
            f.rect(cx + 2, ry, CW - 4, 54, fill=fill, rx=2)
            f.text(cx + CW / 2, ry + 23, str(idx), size=MD, weight="bold", anchor="middle")
            f.text(cx + CW / 2, ry + 44, f"{x},{y},{z}", anchor="middle")
    f.text(34, oy + 152, "X змінюється найшвидше, потім Y, потім Z.  "
           "Крок по X = 1, по Y = sizeX, по Z = sizeX·sizeY.")
    oy = 530
    f.text(20, oy, "Перевірка формули: кожен блок має отримати СВІЙ номер (світ 48×48×24)",
           weight="bold", size=MD)
    cols = (40, 170, 470)
    for x, s, color in zip(cols, ("блок", "правильно: x + sx·(y + sy·z)", "помилка: x + sx·y + sy·z"),
                           (INK, GREEN, RED)):
        f.text(x, oy + 36, s, weight="bold", color=color)
    rows = (("(0, 1, 0)", "0 + 48·(1 + 48·0) = 48", "0 + 48·1 + 48·0 = 48"),
            ("(0, 0, 1)", "0 + 48·(0 + 48·1) = 2304", "0 + 48·0 + 48·1 = 48  ← той самий!"))
    for k, row in enumerate(rows):
        for x, s, color in zip(cols, row, (INK, GREEN, RED)):
            f.text(x, oy + 66 + k * 30, s, mono=True, color=color)
    f.save(out("flat_index"))


def surface_height(x, y):
    """Copy of surfaceHeight from 06-world/code/src/world/generate.lua."""
    h = 10 + 3 * math.sin(x / 6) + 3 * math.cos(y / 7) + 2 * math.sin((x + y) / 9)
    return max(4, min(24 - 2, math.floor(h)))


def cmap_hex(name, t):
    import matplotlib
    r, g, b, _ = matplotlib.colormaps[name](t)
    return f"#{round(r * 255):02x}{round(g * 255):02x}{round(b * 255):02x}"


def height_cells(f, ox, oy, cell, color_of, n=48):
    """Heightmap as vector cells; neighbouring cells of the same colour in a row
    are merged into one rectangle to keep the file small."""
    for y in range(n):
        x = 0
        while x < n:
            c = color_of(x, y)
            x2 = x
            while x2 + 1 < n and color_of(x2 + 1, y) == c:
                x2 += 1
            f.rect(ox + x * cell, oy + (n - 1 - y) * cell, (x2 - x + 1) * cell + 0.3, cell + 0.3,
                   fill=c, check=False)
            x = x2 + 1


@diagram("06-world", "heightmap")
def heightmap():
    f = Fig(900, 430, "Карта висот і розріз світу")
    f.text(20, 30, "Карта висот: surfaceHeight(x, y)", size=MD, weight="bold")
    ox, oy, cell, n = 60, 70, 6, 48
    height_cells(f, ox, oy, cell, lambda x, y: cmap_hex("terrain", surface_height(x, y) / 24))
    f.rect(ox, oy, n * cell, n * cell, stroke=GRAY, sw=THIN, check=False)
    for t in range(0, 48, 10):
        f.text(ox + (t + 0.5) * cell, oy + n * cell + 20, str(t), anchor="middle")
        f.text(ox - 8, oy + (n - t - 0.5) * cell + 4, str(t), anchor="end")
    f.text(ox + n * cell / 2, oy + n * cell + 42, "x", anchor="middle")
    f.text(ox - 30, oy - 10, "y")
    ly = oy + (n - 20 - 0.5) * cell
    f.line(ox, ly, ox + n * cell, ly, stroke=RED, sw=WIDE, dash="7 4", check=False)
    f.text(ox + 8, ly - 7, "розріз y = 20", color=RED, weight="bold", halo="#ffffff")
    # Colour scale.
    bx = ox + n * cell + 20
    for i in range(48):
        f.rect(bx, oy + n * cell - (i + 1) * cell, 14, cell + 0.3,
               fill=cmap_hex("terrain", (i + 0.5) / 48), check=False)
    f.rect(bx, oy, 14, n * cell, stroke=GRAY, sw=THIN, check=False)
    for t in range(0, 25, 5):
        f.text(bx + 20, oy + n * cell - t / 24 * n * cell + 4, str(t))
    f.text(bx - 4, oy - 10, "висота, блоків")
    # Right: cross-section of the columns at y = 20.
    f.text(480, 30, "Розріз світу при y = 20", size=MD, weight="bold")
    sx, sy, sc = 500, 120, 8
    base = sy + 24 * sc
    kinds = ((GRASS_C, "трава: верхній блок"), (DIRT_C, "земля: 3 блоки під травою"),
             (STONE_C, "камінь: решта"))
    # The legend goes in the empty part of the section (only air above the terrain there).
    for k, (color, label) in enumerate(kinds):
        ly = sy + 8 + k * 22
        f.rect(sx + 12, ly, 12, 12, fill=color)
        f.text(sx + 30, ly + 11, label)
    for x in range(48):
        h = surface_height(x, 20)
        for z in range(h):
            color = GRASS_C if z == h - 1 else DIRT_C if z >= h - 4 else STONE_C
            f.rect(sx + x * sc, base - (z + 1) * sc, sc, sc, fill=color, stroke="#ffffff", sw=0.5,
                   check=False)
    f.line(sx, base, sx + 48 * sc, base, stroke=GRAY, owner="axis")
    f.line(sx, sy, sx, base, stroke=GRAY, owner="axis")
    for t in range(0, 48, 10):
        f.text(sx + (t + 0.5) * sc, base + 20, str(t), anchor="middle")
    for t in range(0, 25, 5):
        f.text(sx - 8, base - t * sc + 4, str(t), anchor="end")
    f.text(sx + 24 * sc, base + 42, "x", anchor="middle")
    f.text(sx - 30, sy - 12, "z (висота)")
    f.save(out("heightmap"))


# ---------------------------------------------------------------- 07-culling-chunks

@diagram("07-culling-chunks", "chunks")
def chunks():
    f = Fig(560, 580, "Світ 48×48×24, поділений на чанки 16³")
    f.text(280, 28, "Світ 48×48×24 = 3×3×2 чанки по 16³", size=MD, weight="bold", anchor="middle")
    f.text(280, 50, "(вид згори, нижній шар z = 0..15)", anchor="middle")
    ox, oy, cell, n = 80, 80, 9, 48
    height_cells(f, ox, oy, cell, lambda x, y: cmap_hex("Greens", 0.08 + surface_height(x, y) / 24 * 0.45))
    for k in range(4):
        f.line(ox + k * 16 * cell, oy, ox + k * 16 * cell, oy + n * cell, stroke=INK, sw=WIDE, owner="chunk")
        f.line(ox, oy + k * 16 * cell, ox + n * cell, oy + k * 16 * cell, stroke=INK, sw=WIDE, owner="chunk")
        f.text(ox + k * 16 * cell, oy + n * cell + 22, str(16 * k), anchor="middle")
        f.text(ox - 10, oy + (n - 16 * k) * cell + 4, str(16 * k), anchor="end")
    f.rect(ox + 16 * cell + 3, oy + 16 * cell + 3, 16 * cell - 6, 16 * cell - 6, stroke=ORANGE, sw=3,
           check=False)
    for j in range(3):
        for i in range(3):
            cx = ox + (i + 0.5) * 16 * cell
            cy = oy + (2.5 - j) * 16 * cell
            f.text(cx, cy - 4, f"чанк ({i}, {j}, 0)\nключ {i + 3 * j}", weight="bold", anchor="middle")
    f.text(ox + n * cell / 2, oy + n * cell + 46, "x, блоки", anchor="middle")
    f.text(ox - 40, oy - 22, "y, блоки")
    f.save(out("chunks"))


@diagram("07-culling-chunks", "hidden_faces")
def hidden_faces():
    f = Fig(880, 400, "Розріз світу: видимі та приховані грані")
    f.text(20, 30, "Розріз світу: які грані справді видно", size=MD, weight="bold")
    heights = [3, 3, 4, 5, 5, 4, 2, 2]
    C, ox, base = 60, 30, 370
    colors = {0: "#a6cc91", 1: "#b3a090", 2: "#b8b8b8"}
    solid = {(x, z) for x, h in enumerate(heights) for z in range(h)}
    for x, z in solid:
        kind = min(heights[x] - 1 - z, 2)
        f.rect(ox + x * C, base - (z + 1) * C, C, C, fill=colors[kind], check=False)
    visible = hidden = 0
    for x, z in solid:
        x0, y0 = ox + x * C, base - (z + 1) * C
        for (dx, dz), seg in (((1, 0), (x0 + C, y0, x0 + C, y0 + C)), ((-1, 0), (x0, y0, x0, y0 + C)),
                              ((0, 1), (x0, y0, x0 + C, y0)), ((0, -1), (x0, y0 + C, x0 + C, y0 + C))):
            if (x + dx, z + dz) in solid:
                hidden += 1
                if dx > 0 or dz > 0:   # draw a shared face only once
                    f.line(*seg, stroke=RED, sw=1.5, dash="3 3", owner="hidden")
            else:
                visible += 1
                f.line(*seg, stroke=GREEN, sw=XWIDE, owner="visible")
    lx = 560
    f.line(lx, 120, lx + 44, 120, stroke=GREEN, sw=XWIDE)
    f.text(lx + 54, 125, "грань біля повітря — малюємо")
    f.line(lx, 155, lx + 44, 155, stroke=RED, sw=1.5, dash="3 3")
    f.text(lx + 54, 160, "між двома блоками —\nпропускаємо")
    f.text(lx, 240, f"у цьому розрізі:\n{visible} видимих граней\n{hidden} прихованих", weight="bold",
           size=MD)
    f.save(out("hidden_faces"))


@diagram("07-culling-chunks", "triangle_counts")
def triangle_counts():
    f = Fig(860, 250, "Кількість трикутників до і після відсікання прихованих граней")
    f.text(20, 30, "Острів 48×48×24: 23 451 твердий блок", size=MD, weight="bold")
    ox, w, scale = 220, 460, 460 / 281412
    rows = (("урок 6: усі 6 граней\nкожного блока", 281412, RED),
            ("урок 7: лише грані\nбіля повітря", 16860, GREEN))
    for k, (label, value, color) in enumerate(rows):
        y = 60 + k * 90
        f.rect(ox, y, value * scale, 56, fill=color)
        f.text(ox - 12, y + 24, label, anchor="end")
        f.text(ox + value * scale + 10, y + 33, f"{value:,}".replace(",", " ") + " трикутників",
               weight="bold")
    f.line(ox, 50, ox, 220, stroke=GRAY, owner="axis")
    f.text(ox + 250, 60 + 90 + 33, f"у {281412 / 16860:.1f} раза менше".replace(".", ","),
           color=GREEN, weight="bold", size=MD)
    f.save(out("triangle_counts"))


@diagram("07-culling-chunks", "winding")
def winding():
    f = Fig(860, 400, "Порядок обходу вершин: лицьова і тильна сторона")
    panels = ((40, "Дивимося ззовні:\n1→2→3 проти год. стрілки", GREEN, "#c1dfc5", (1, 2),
               "лицьова (front) — малюється", GREEN),
              (470, "Той самий △ ззаду:\nобхід за год. стрілкою", GRAY, "#d4d7dc", (2, 1),
               "тильна (back) — відкидається", RED))
    for ox, title, color, fill, (left, right), caption, ccolor in panels:
        f.text(ox + 180, 28, title, size=MD, weight="bold", color=color, anchor="middle")
        A, B, T = (ox + 60, 310), (ox + 300, 310), (ox + 180, 100)
        f.poly([A, B, T], fill=fill, stroke=color, sw=WIDE)
        for p in (A, B, T):
            f.circle(*p, 5)
        f.text(A[0] - 14, A[1] + 22, str(left), size=MD, weight="bold", anchor="middle")
        f.text(B[0] + 14, B[1] + 22, str(right), size=MD, weight="bold", anchor="middle")
        f.text(T[0], T[1] - 14, "3", size=MD, weight="bold", anchor="middle")
        # Winding arrows 1→2→3→1 inside the triangle, parallel to its sides.
        pts = {1: A if left == 1 else B, 2: B if left == 1 else A, 3: T}
        cen = ((A[0] + B[0] + T[0]) / 3, (A[1] + B[1] + T[1]) / 3)
        for a, b in ((1, 2), (2, 3), (3, 1)):
            p, q = pts[a], pts[b]
            mid = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            d = (q[0] - p[0], q[1] - p[1])
            L = math.hypot(*d)
            u = (d[0] / L, d[1] / L)
            inward = (cen[0] - mid[0], cen[1] - mid[1])
            il = math.hypot(*inward)
            off = (inward[0] / il * 26, inward[1] / il * 26)
            s = (mid[0] + off[0] - u[0] * 60, mid[1] + off[1] - u[1] * 60)
            e = (mid[0] + off[0] + u[0] * 60, mid[1] + off[1] + u[1] * 60)
            f.arrow([s, e], color=INK, sw=WIDE)
        f.text(ox + 180, 375, caption, weight="bold", color=ccolor, size=MD, anchor="middle")
    f.save(out("winding"))


# ---------------------------------------------------------------- 08-vox

VOX = os.path.join(ROOT, "08-vox", "code", "assets", "worlds", "test.vox")
BLOCK_COLORS = (("STONE", (125, 125, 125), STONE_C), ("DIRT", (121, 85, 58), DIRT_C),
                ("GRASS", (95, 159, 53), GRASS_C))


@diagram("08-vox", "axes")
def axes():
    f = Fig(860, 360, "Системи координат: Z угору і Y угору")
    panels = ((40, "MagicaVoxel / .vox і наша гра:\nZ — вгору",
               {"X": ((1, 0.32), RED), "Y": ((0.62, -0.42), GREEN), "Z": ((0, -1), BLUE)}, "Z"),
              (470, "OpenGL, Unity, багато рушіїв:\nY — вгору",
               {"X": ((1, 0.32), RED), "Y": ((0, -1), GREEN), "Z": ((-0.62, 0.42), BLUE)}, "Y"))
    for ox, title, dirs, up in panels:
        f.text(ox, 30, title, size=MD, weight="bold")
        o = (ox + 140, 250)
        for name, ((dx, dy), color) in dirs.items():
            L = 140 if name != ("Y" if up == "Z" else "Z") else 90
            tip = (o[0] + dx * L, o[1] + dy * L)
            f.arrow([o, tip], color=color, sw=XWIDE)
            lx = tip[0] + (14 if dx >= 0 else -14) * (1 if dx else 0)
            ly = tip[1] + (-12 if dy < -0.5 else 22 if dy > 0.2 else 6)
            f.text(lx, ly, name + (" ↑" if name == up else ""), color=color, weight="bold", size=LG,
                   anchor="middle" if dx == 0 else "start" if dx > 0 else "end")
    f.save(out("axes"))


@diagram("08-vox", "color_match")
def color_match():
    f = Fig(900, 330, "Blocks.fromColor: пошук найближчого кольору")
    f.text(450, 30, "Blocks.fromColor: блок з найменшою «відстанню» між кольорами", size=MD,
           weight="bold", anchor="middle")
    voxels = ((110, 140, 60), (90, 90, 90), (150, 100, 70))
    W, scale = 165, 165 / 7000
    for p, rgb in enumerate(voxels):
        x0 = 20 + p * 295
        bx = x0 + 60
        f.text(x0, 70, f"воксель {rgb}", weight="bold")
        f.rect(x0 + 190, 54, 34, 22, fill="#%02x%02x%02x" % rgb, stroke=INK, sw=THIN)
        dist = [sum((a - b) ** 2 for a, b in zip(rgb, c)) for _, c, _ in BLOCK_COLORS]
        best = dist.index(min(dist))
        for k, ((name, _, color), dv) in enumerate(zip(BLOCK_COLORS, dist)):
            y = 92 + k * 58
            f.rect(bx, y, dv * scale, 42, fill=color)
            f.text(bx - 8, y + 26, name, anchor="end")
            f.text(bx + dv * scale + 6, y + 26, f"{dv}" + ("  ← найближчий" if k == best else ""),
                   weight="bold" if k == best else "normal")
        f.line(bx, 86, bx, 270, stroke=GRAY, owner="axis")
        f.line(bx, 270, bx + W, 270, stroke=GRAY, owner="axis")
        for t in (0, 3000, 6000):
            f.line(bx + t * scale, 270, bx + t * scale, 274, stroke=GRAY, check=False)
            f.text(bx + t * scale, 290, str(t), anchor="middle")
        f.text(bx + W / 2, 314, "dr² + dg² + db²", anchor="middle")
    f.save(out("color_match"))


def byte_char(b):
    return chr(b) if 32 < b < 127 else "·"


@diagram("08-vox", "hexdump")
def hexdump():
    data = open(VOX, "rb").read(80)
    u32 = lambda i: int.from_bytes(data[i:i + 4], "little")  # noqa: E731
    f = Fig(860, 520, "Перші 80 байтів test.vox")
    f.text(20, 30, "Перші 80 байтів test.vox (xxd): кожна клітинка — один байт", size=MD,
           weight="bold")
    region = [(0, GRAY), (8, PURPLE), (20, BLUE), (44, ORANGE), (60, RED)]

    def color_of(i):
        return [c for start, c in region if i >= start][-1]

    labels = ["«VOX »", f"версія {u32(4)}", "«MAIN»", f"вміст {u32(12)}",
              f"дочірні {u32(16)}", "«SIZE»", f"вміст {u32(24)}", f"дочірні {u32(28)}",
              f"x = {u32(32)}", f"y = {u32(36)}", f"z = {u32(40)}", "«XYZI»",
              f"вміст {u32(48)}", f"дочірні {u32(52)}", f"N = {u32(56)}"]
    labels += [f"воксель ({data[i]},{data[i + 1]},{data[i + 2]}) i={data[i + 3]}" for i in range(60, 80, 4)]
    CW, X0 = 46, 80
    for row in range(5):
        y = 50 + row * 84
        f.text(20, y + 26, f"{row * 16:04x}", mono=True, color=MUTED)
        for col in range(16):
            i = row * 16 + col
            c = color_of(i)
            x = X0 + col * CW
            f.rect(x, y, CW - 4, 46, fill=FILL[c], stroke=c, sw=THIN, rx=2)
            f.text(x + (CW - 4) / 2, y + 18, f"{data[i]:02x}", mono=True, weight="bold", anchor="middle")
            f.text(x + (CW - 4) / 2, y + 39, byte_char(data[i]), mono=True, color=MUTED, anchor="middle")
        for g in range(4):
            i = row * 16 + g * 4
            c = color_of(i)
            gx = X0 + g * 4 * CW
            f.line(gx, y + 54, gx + 4 * CW - 4, y + 54, stroke=c, sw=3, owner="group")
            f.text(gx + (4 * CW - 4) / 2, y + 72, labels[row * 4 + g], color=c, weight="bold",
                   anchor="middle")
    f.text(20, 485, f"Байти 96 00 00 00 = 0x00000096 = {u32(4)}: молодший байт іде першим (little-endian).\n"
           "Вокселі — по 4 байти: x, y, z, індекс кольору.")
    f.save(out("hexdump"))


@diagram("08-vox", "little_endian")
def little_endian():
    data = open(VOX, "rb").read(20)[16:20]
    value = int.from_bytes(data, "little")
    f = Fig(860, 230, "Little-endian: молодший байт першим")
    f.text(20, 30, f"Little-endian: число {value:,} у файлі записано як ".replace(",", " ")
           + " ".join(f"{b:02x}" for b in data), size=MD, weight="bold")
    for k, b in enumerate(data):
        x = 20 + k * 100
        f.rect(x, 52, 90, 66, fill=FILL[PURPLE], stroke=PURPLE, sw=THIN, rx=3)
        f.text(x + 45, 80, f"{b:02x}", mono=True, weight="bold", size=MD, anchor="middle")
        f.text(x + 45, 104, f"b{k + 1} = {b}", anchor="middle")
        f.text(x + 45, 144, "× 1" if k == 0 else "× 256" if k == 1 else f"× 256{'²³'[k - 2]}",
               color=PURPLE, weight="bold", size=MD, anchor="middle")
    terms = " + ".join(f"{b}·{256 ** k:,}".replace(",", " ") if k else str(b) for k, b in enumerate(data))
    f.text(430, 80, "= " + terms.replace("·1 ", " ").replace("114·256", "114·256"), mono=True)
    f.text(430, 104, f"= {value:,}".replace(",", " "), mono=True, weight="bold")
    f.text(20, 200, "readU32: b1 + b2·0x100 + b3·0x10000 + b4·0x1000000   (розмір дочірніх чанків MAIN)",
           mono=True)
    f.save(out("little_endian"))


def fields(f, x, y, cells, color, fill=None, dashed=False, value_color=INK, caption_color=INK, h=48):
    """A row of .vox chunk fields: [(value, caption)], each field sized to its text.
    Returns the field boxes (x0, y0, x1, y1)."""
    boxes = []
    for value, caption in cells:
        w = max(text_width(value, SM, "bold", mono=True), text_width(caption, SM)) + 18
        f.rect(x, y, w, h, fill=fill or FILL[color], stroke=color, sw=THIN, dash="5 3" if dashed else None)
        f.text(x + w / 2, y + 19, value, mono=True, weight="bold", anchor="middle", color=value_color)
        f.text(x + w / 2, y + 39, caption, anchor="middle", color=caption_color)
        boxes.append((x, y, x + w, y + h))
        x += w
    return boxes


@diagram("08-vox", "vox_format")
def vox_format():
    data = open(VOX, "rb").read()
    u32 = lambda i: int.from_bytes(data[i:i + 4], "little")  # noqa: E731
    f = Fig(900, 1070, "Формат MagicaVoxel .vox")
    size = f"{len(data):,}".replace(",", " ")
    f.text(450, 30, f"Формат MagicaVoxel .vox (наш файл assets/worlds/test.vox, {size} байтів)",
           size=MD, weight="bold", anchor="middle")
    f.text(450, 54, "Усі числа — u32: 4 байти, молодший перший (little-endian).\n"
           "Файл — дерево «чанків»: заголовок + вміст + дочірні чанки.", anchor="middle")
    # Header and MAIN.
    f.text(110, 124, "заголовок", weight="bold", color=GRAY, anchor="end")
    b = fields(f, 120, 100, [('"VOX "', "сигнатура"), (str(u32(4)), "версія, u32")], GRAY)
    f.text(b[-1][2] + 12, 126, "← якщо перші 4 байти не «VOX », це не наш формат: помилка", color=GRAY)
    f.text(110, 184, "MAIN", weight="bold", color=PURPLE, anchor="end")
    b = fields(f, 120, 160, [('"MAIN"', "id, 4 байти"), (str(u32(12)), "вміст, u32"),
                             (str(u32(16)), "дочірні, u32")], PURPLE)
    f.text(b[-1][2] + 12, 186, "← корінь: власного вмісту немає,\n    усе — у дочірніх чанках", color=PURPLE)
    # Container of MAIN's child chunks.
    f.rect(40, 230, 845, 755, stroke=PURPLE, sw=1.5, dash="2 4")
    f.text(875, 250, "дочірні чанки MAIN", color=PURPLE, style="italic", anchor="end")
    X = 130
    f.text(X - 12, 294, "SIZE", weight="bold", color=BLUE, anchor="end")
    b = fields(f, X, 270, [('"SIZE"', "id, 4 байти"), (str(u32(24)), "вміст, u32"),
                           (str(u32(28)), "дочірні, u32"), (str(u32(32)), "x"), (str(u32(36)), "y"),
                           (str(u32(40)), "z")], BLUE)
    f.text(b[-1][2] + 12, 296, "розмір моделі → Extent3", color=BLUE)
    f.text(X - 12, 374, "XYZI", weight="bold", color=ORANGE, anchor="end")
    n = u32(56)
    v0 = data[60:64]
    v1 = data[64:68]
    b = fields(f, X, 350, [('"XYZI"', "id, 4 байти"), (str(u32(48)), "вміст, u32"),
                           (str(u32(52)), "дочірні, u32"), (str(n), "N, u32"),
                           (" ".join(map(str, v0)), "x y z i"), (" ".join(map(str, v1)), "x y z i"),
                           ("…", "ще N−2")], ORANGE)
    vox0 = b[4]
    f.rect(vox0[0] + 2, vox0[1] + 2, vox0[2] - vox0[0] - 4, vox0[3] - vox0[1] - 4, stroke=RED, sw=WIDE,
           check=False)
    f.text(X, 416, "N вокселів по 4 байти: координати + індекс кольору i", color=ORANGE)
    # The SIZE + XYZI pair: its label goes in the gap between their rows.
    f.text(X, 337, "↕ пара SIZE + XYZI = одна модель", color=BLUE, weight="bold")
    # RGBA.
    pal = [data[i:i + 4] for i in range(len(data) - 1024, len(data), 4)]
    f.text(X - 12, 514, "RGBA", weight="bold", color=GREEN, anchor="end")
    rgba_cells = [('"RGBA"', "id, 4 байти"), ("1024", "вміст, u32"), ("0", "дочірні, u32")]
    rgba_cells += [(" ".join(map(str, pal[k])), f"запис {k} → індекс {k + 1}") for k in range(3)]
    rgba_cells += [("…", "до 256")]
    b = fields(f, X, 490, rgba_cells, GREEN)
    f.text(X, 556, "палітра: 256 кольорів по 4 байти", color=GREEN)
    # From i = 1 to palette record 0.
    rec0 = b[3]
    f.curve_arrow(((vox0[0] + vox0[2]) / 2, vox0[3] + 2), ((vox0[0] + vox0[2]) / 2, 450),
                  ((rec0[0] + rec0[2]) / 2 + 40, 440), ((rec0[0] + rec0[2]) / 2 + 20, rec0[1] - 2),
                  color=RED, sw=WIDE)
    f.text((vox0[0] + vox0[2]) / 2 + 20, 456, f"i = {v0[3]}  →  запис i − 1 = {v0[3] - 1}", color=RED,
           weight="bold")
    # fromColor.
    fx, fy = 200, 610
    f.rect(fx, fy, 260, 46, fill=FILL[YELLOW], stroke=YELLOW, sw=WIDE, rx=4)
    f.text(fx + 130, fy + 29, "Blocks.fromColor(r, g, b)", mono=True, weight="bold", anchor="middle")
    for k in range(3):
        cx = (b[3 + k][0] + b[3 + k][2]) / 2
        f.arrow([(cx, b[3 + k][3] + 26), (fx + 60 + k * 70, fy - 2)], color=INK, sw=THIN)
    f.arrow([(fx + 262, fy + 23), (fx + 300, fy + 23)], color=INK, sw=WIDE)
    for k, (name, _, color) in enumerate(BLOCK_COLORS):
        x = fx + 304 + k * 120
        f.rect(x, fy, 110, 46, fill=color, rx=3)
        f.text(x + 55, fy + 29, f"{name} ({k + 1})", color="#ffffff", weight="bold", anchor="middle")
    f.text(fx, fy + 72, "найближчий еталонний колір → id блока → World")
    # Chunks we skip.
    sy = 720
    f.text(X - 60, sy, "Інші дочірні чанки, які пише MagicaVoxel. Ми їх ПРОПУСКАЄМО (у нашому файлі їх немає):",
           weight="bold", color=GRAY)
    skip_fill = "#eceef1"
    rows = (("nTRN", "вузол-перетворення сцени: зсув і поворот"), ("nGRP", "група вузлів сцени"),
            ("nSHP", "вузол-форма: посилання на модель"))
    for k, (cid, desc) in enumerate(rows):
        y = sy + 50 + k * 54
        f.text(X - 12, y + 24, cid, weight="bold", color=GRAY, anchor="end")
        b = fields(f, X, y, [(f'"{cid}"', "id, 4 байти"), ("n", "вміст, u32"), ("m", "дочірні, u32"),
                             ("… n байтів …", "DICT, масиви")], GRAY, fill=skip_fill, dashed=True,
                   value_color=MUTED, caption_color=MUTED)
        f.text(b[-1][2] + 12, y + 26, desc, color=MUTED)
        if k == 0:
            f.curve_arrow((X, y - 4), (X + 60, y - 30), (b[-1][2] - 60, y - 30), (b[-1][2], y - 4),
                          color=RED, sw=WIDE)
            f.text(b[-1][2] + 12, y - 12, "перестрибнути:\npos = pos + 12 + contentSize + childrenSize",
                   color=RED, weight="bold", mono=False)
    f.text(X, sy + 230, "…а також MATL (матеріали), LAYR (шари редактора), rOBJ / rCAM (рендер і камери),\n"
           "NOTE, IMAP", color=MUTED)
    f.text(40, 1010, "Сцена потрібна, коли файл містить кілька моделей у різних місцях. Наш світ — одна\n"
           "модель, тому сцена, матеріали й шари не впливають на те, які блоки де стоять.\n"
           "Пропускаємо, але не ламаємося, коли вони є.")
    f.save(out("vox_format"))


# ---------------------------------------------------------------- 09-interaction

@diagram("09-interaction", "chunks_touching")
def chunks_touching():
    f = Fig(860, 420, "Renderer.chunksTouching: які чанки зачіпає зміна блока")
    f.text(430, 28, "Renderer.chunksTouching (вид згори; так само працює і по осі z)",
           size=MD, weight="bold", anchor="middle")
    U = 6.25   # pixels per block: a 16-block chunk = 100 px
    panels = ((60, "блок усередині чанка: 1 чанк", (20, 22), {(1, 1): "свій чанк"}),
              (480, "блок на межі: 3 чанки", (16, 31),
               {(1, 1): "свій чанк", (0, 1): "сусід", (1, 2): "сусід"}))
    for ox, title, block, marked in panels:
        oy = 80
        f.text(ox + 150, oy - 14, title, size=MD, weight="bold", anchor="middle")
        for j in range(3):
            for i in range(3):
                label = marked.get((i, j))
                fill = "#ffffff" if not label else FILL[ORANGE] if label == "свій чанк" else "#f6e7aa"
                f.rect(ox + i * 100, oy + (2 - j) * 100, 100, 100, fill=fill, stroke=INK, sw=WIDE)
                if label:
                    f.text(ox + i * 100 + 50, oy + (2 - j) * 100 + 30, label, weight="bold",
                           anchor="middle")
        for k in range(4):
            f.text(ox + k * 100, oy + 326, str(16 * k), anchor="middle")
            f.text(ox - 8, oy + 300 - k * 100 + 4, str(16 * k), anchor="end")
        bx, by = ox + (block[0] + 0.5) * U, oy + 300 - (block[1] + 0.5) * U
        f.rect(bx - U / 2, by - U / 2, U, U, fill=RED, check=False)
        # The block label goes in an empty chunk, so its leader doesn't run through other labels.
        tx, ty = (ox + 250, oy + 260) if len(marked) == 1 else (ox + 250, oy + 60)
        lbl = f"блок {block}"
        f.text(tx, ty, lbl, color=RED, weight="bold", anchor="middle")
        # The leader starts at the middle of the label's left edge (ISO 128).
        f.leader((tx - text_width(lbl, SM, "bold") / 2 - 5, ty - 4), (bx + 3, by + 3), color=RED,
                 end="arrow")
    f.save(out("chunks_touching"))


def traverse(origin, direction, max_cells=40):
    """Amanatides & Woo in 2D, as in src/world/raycast.lua. Returns [(cell, entry point, normal)]."""
    cell = [math.floor(origin[0]), math.floor(origin[1])]
    step = [1 if d > 0 else -1 for d in direction]
    spacing = [abs(1 / d) for d in direction]
    nxt = [((cell[a] + (1 if step[a] > 0 else 0)) - origin[a]) / direction[a] for a in (0, 1)]
    out_ = [(tuple(cell), origin, (0, 0))]
    for _ in range(max_cells):
        a = 0 if nxt[0] < nxt[1] else 1
        t = nxt[a]
        cell[a] += step[a]
        normal = (-step[0], 0) if a == 0 else (0, -step[1])
        out_.append((tuple(cell), (origin[0] + direction[0] * t, origin[1] + direction[1] * t), normal))
        nxt[a] += spacing[a]
    return out_


@diagram("09-interaction", "raycast")
def raycast():
    f = Fig(900, 365, "Обхід клітинок Amanatides & Woo і наївний спосіб")
    solid = {(5, 0), (6, 0), (7, 0), (7, 1), (7, 2), (7, 3), (6, 4)}
    origin, end = (0.6, 0.7), (8.9, 5.1)
    L = math.hypot(end[0] - origin[0], end[1] - origin[1])
    d = ((end[0] - origin[0]) / L, (end[1] - origin[1]) / L)
    path = []
    for cell, entry, normal in traverse(origin, d):
        path.append((cell, entry, normal))
        if cell in solid or cell == (6, 3):
            break
    hit, _, hit_normal = path[-1]
    U = 44
    for k, (ox, title) in enumerate(((40, "Amanatides & Woo:\nкожна клітинка на шляху"),
                                     (480, "Наївно:\nточки через кожні 0.5 блока"))):
        oy = 80

        def P(x, y, ox=ox):
            return (ox + x * U, oy + 5.5 * U - y * U)

        f.text(ox - 20, 26, title, size=MD, weight="bold")
        for t in range(10):
            f.line(*P(t, 0), *P(t, 5.5), stroke=GRID, check=False)
            f.text(P(t, 0)[0], P(t, 0)[1] + 24, str(t), anchor="middle")
        for t in range(6):
            f.line(*P(0, t), *P(9, t), stroke=GRID, check=False)
            f.text(P(0, t)[0] - 8, P(0, t)[1] + 4, str(t), anchor="end")
        for c in solid:
            f.rect(*P(c[0], c[1] + 1), U, U, fill=STONE_C, stroke="#ffffff", sw=THIN)
        f.rect(*P(hit[0], hit[1] + 1), U, U, fill=ORANGE, stroke="#ffffff", sw=THIN)
        if k == 0:
            for n, (c, entry, _) in enumerate(path):
                if c != hit:
                    f.rect(*P(c[0], c[1] + 1), U, U, fill="#d5e2f8", stroke=BLUE, sw=1.5)
                # The number goes in the half of the cell the ray doesn't cross.
                ray_y = origin[1] + (c[0] + 0.5 - origin[0]) * d[1] / d[0]
                dy = 0.25 if ray_y < c[1] + 0.5 else -0.25
                tx, ty = P(c[0] + 0.5, c[1] + 0.5 + dy)
                f.text(tx, ty + 4.5, str(n), weight="bold", anchor="middle",
                       color="#ffffff" if c == hit else INK)
        else:
            samples = [(origin[0] + d[0] * t * 0.5, origin[1] + d[1] * t * 0.5) for t in range(40)]
            samples = [s for s in samples if s[0] < 6.6]
            sampled = {(math.floor(x), math.floor(y)) for x, y in samples}
            for c, _, _ in path:
                if c not in sampled and c != hit:
                    f.rect(*P(c[0], c[1] + 1), U, U, fill="url(#hatch)", stroke=RED, sw=WIDE)
        f.arrow([P(*origin), P(*end)], color=RED, sw=WIDE)
        if k == 0:
            for _, entry, _ in path[1:]:
                f.circle(*P(*entry), 3, check=False)
        else:
            for s in samples:
                f.circle(*P(*s), 4, fill=PURPLE, check=False)
        f.circle(*P(*origin), 7, fill=RED)
        f.text(P(0.1, 2.6)[0], P(0.1, 2.6)[1], "камера", color=RED, weight="bold")
        f.leader((P(0.5, 2.3)[0], P(0.5, 2.3)[1]), P(origin[0], origin[1] + 0.2), color=RED, end="arrow")
        if k == 0:
            place = (hit[0] + hit_normal[0], hit[1] + hit_normal[1])
            f.rect(*P(place[0], place[1] + 1), U, U, stroke=GREEN, sw=3, dash="6 4", check=False)
            f.arrow([P(hit[0] + 0.1, hit[1] + 0.15), P(hit[0] - 0.45, hit[1] + 0.15)], color=GREEN, sw=3)
            # Labels go in empty cells: below the hit and at the top left.
            f.text(*P(5.55, 1.4), f"normal = ({hit_normal[0]}, {hit_normal[1]})".replace("-", "−"),
                   color=GREEN, weight="bold", anchor="middle")
            f.leader(P(5.55, 1.75), P(hit[0] - 0.2, hit[1] + 0.42), color=GREEN, end="arrow")
            f.text(*P(0.15, 4.85), "сюди ставимо блок:\nhit.block + normal", color=GREEN, weight="bold")
            f.leader(P(2.9, 4.3), P(place[0] + 0.1, place[1] + 0.9), color=GREEN, end="arrow")
    f.defs.append('<pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse"'
                  ' patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="8"'
                  f' stroke="{RED}" stroke-width="1.2"/></pattern>')
    f.save(out("raycast"))


# ---------------------------------------------------------------- 10-final

LESSONS = ("01-window", "02-triangle", "03-perspective", "04-camera", "05-textures", "06-world",
           "07-culling-chunks", "08-vox", "09-interaction", "10-final")
LESSON_NAMES = ("вікно", "трикутник", "перспектива", "камера", "текстури", "світ", "чанки", ".vox",
                "взаємодія", "фінал")
REFERENCE_LINES = 1493   # the love-mcraft reference project


def lua_stats(lesson):
    """(non-empty lines, files) in a lesson's code, excluding tests."""
    lines = files = 0
    for dirpath, dirnames, filenames in os.walk(os.path.join(ROOT, lesson, "code")):
        if "tests" in dirpath.split(os.sep):
            continue
        for name in filenames:
            if name.endswith(".lua"):
                files += 1
                with open(os.path.join(dirpath, name), encoding="utf-8") as fh:
                    lines += sum(1 for line in fh if line.strip())
    return lines, files


@diagram("10-final", "code_growth")
def code_growth():
    f = Fig(900, 420, "Як зростав код від уроку до уроку")
    f.text(450, 30, "Як зростав код від уроку до уроку", size=MD, weight="bold", anchor="middle")
    c = Chart(f, 70, 80, 820, 270, (0, 10), (0, 1600), yticks=range(0, 1601, 400),
              ylabel="непорожніх рядків Lua")
    for k, (lesson, name) in enumerate(zip(LESSONS, LESSON_NAMES)):
        lines, files = lua_stats(lesson)
        x0 = c.px(k + 0.15)
        f.rect(x0, c.py(lines), c.px(k + 0.85) - x0, c.py(0) - c.py(lines),
               fill=GREEN if k == len(LESSONS) - 1 else BLUE)
        f.text(c.px(k + 0.5), c.py(lines) - 22, f"{lines}\n({files} ф.)", anchor="middle")
        f.text(c.px(k + 0.5), c.py(0) + 20, f"{k + 1}\n{name}", anchor="middle")
    y = c.py(REFERENCE_LINES)
    f.line(c.x, y, c.x + c.w, y, stroke=GRAY, sw=1.5, dash="7 4", owner="reference")
    f.text(c.px(0.2), y - 8, f"еталон love-mcraft: {REFERENCE_LINES} рядки "
           "(+ сенсорне керування, веб-збірка)", color=MUTED)
    f.save(out("code_growth"))


def require_graph(lesson):
    """A lesson's require() edges: {(module, module)}; names are the last path segment
    ("src.input" and "src.input.init" are both "init")."""
    src = os.path.join(ROOT, lesson, "code")
    alias = {"src.input": "init"}
    edges = set()
    for dirpath, _, filenames in os.walk(src):
        if "tests" in dirpath.split(os.sep):
            continue
        for name in filenames:
            if not name.endswith(".lua") or name == "conf.lua":
                continue
            path = os.path.join(dirpath, name)
            mod = os.path.relpath(path, src)[:-4].replace(os.sep, ".")
            frm = alias.get(mod, mod.split(".")[-1])
            with open(path, encoding="utf-8") as fh:
                for req in re.findall(r'require\("([^"]+)"\)', fh.read()):
                    to = alias.get(req, req.split(".")[-1])
                    if to != frm:
                        edges.add((frm, to))
    return edges


@diagram("10-final", "modules")
def modules():
    f = Fig(940, 680, "Залежності модулів фінальної гри")
    # Packages: (x, y, w, h, label, colour, label at the bottom?). The render and world labels
    # go at the bottom, because edges from game enter those frames from the top.
    packs = {"input": (15, 200, 180, 200, "src/input/", PURPLE, False),
             "render": (230, 200, 425, 212, "src/render/", BLUE, True),
             "world": (680, 200, 245, 312, "src/world/", GREEN, True),
             "math": (230, 535, 695, 90, "src/math/  (без LÖVE)", INK, False)}
    nodes = {"main": (370, 20, 200, 48, "main.lua", "командний рядок, цикл LÖVE", GRAY, None),
             "game": (390, 110, 160, 48, "src/game.lua", "правила гри", ORANGE, None),
             "config": (25, 440, 160, 48, "src/config.lua", "налаштування", YELLOW, None),
             "init": (25, 240, 160, 48, "init.lua", "реєструє callbacks", PURPLE, "input"),
             "mouse_keyboard": (25, 330, 160, 48, "mouse_keyboard.lua", "→ InputFrame", PURPLE, "input"),
             "crosshair": (242, 240, 110, 48, "crosshair.lua", "приціл", BLUE, "render"),
             "camera": (364, 240, 125, 48, "camera.lua", "yaw, pitch, рух", BLUE, "render"),
             "renderer": (501, 240, 142, 48, "renderer.lua", "шейдер, текстури", BLUE, "render"),
             "mesher": (501, 340, 142, 48, "mesher.lua", "чанк → вершини", BLUE, "render"),
             "load": (690, 240, 110, 48, "load.lua", "файл → World", GREEN, "world"),
             "raycast": (812, 240, 103, 48, "raycast.lua", "промінь", GREEN, "world"),
             "vox": (690, 340, 110, 48, "vox.lua", "парсер .vox", GREEN, "world"),
             "world": (812, 340, 103, 48, "world.lua", "сітка блоків", GREEN, "world"),
             "blocks": (745, 437, 120, 48, "blocks.lua", "реєстр блоків", GREEN, "world"),
             "mat4": (420, 565, 100, 40, "mat4.lua", None, INK, "math"),
             "extent3": (630, 565, 110, 40, "extent3.lua", None, INK, "math"),
             "vec3": (800, 565, 100, 40, "vec3.lua", None, INK, "math")}
    for x, y, w, h, label, color, bottom in packs.values():
        f.rect(x, y, w, h, stroke=color, sw=1.5, dash="6 4")
        f.text(x + 10, y + h - 8 if bottom else y + 22, label, weight="bold", color=color)
    for x, y, w, h, title, sub, color, _ in nodes.values():
        f.box(x, y, w, h, title, sub, color, title_size=SM, rx=6)

    E = GRAY
    # Edge routes. Dependencies on src/math are drawn frame to frame: nearly everything uses
    # vec3, and separate arrows to it would cover the diagram.
    routes = {
        ("main", "game"): [(470, 68), (470, 110)],
        ("main", "config"): [(370, 44), (6, 44), (6, 464), (25, 464)],
        ("game", "init"): ("c", (400, 158), (400, 200), (105, 196), (105, 240)),
        ("game", "crosshair"): ("c", (430, 158), (430, 200), (297, 200), (297, 240)),
        ("game", "camera"): [(445, 158), (432, 240)],
        ("game", "renderer"): ("c", (520, 158), (520, 200), (572, 200), (572, 240)),
        ("game", "load"): ("c", (550, 140), (745, 140), (745, 200), (745, 240)),
        ("game", "raycast"): ("c", (550, 126), (863, 126), (863, 200), (863, 240)),
        ("game", "blocks"): [(550, 118), (933, 118), (933, 461), (865, 461)],
        ("game", "config"): [(390, 150), (212, 150), (212, 464), (185, 464)],
        ("game", "math"): [(560, 158), (667, 158), (667, 535)],
        ("init", "mouse_keyboard"): [(105, 288), (105, 330)],
        ("mouse_keyboard", "config"): [(105, 378), (105, 440)],
        ("renderer", "mesher"): [(572, 288), (572, 340)],
        ("renderer", "blocks"): ("c", (643, 270), (674, 290), (672, 440), (745, 452)),
        ("mesher", "blocks"): ("c", (643, 372), (676, 395), (690, 472), (745, 472)),
        ("load", "vox"): [(745, 288), (745, 340)],
        ("load", "world"): ("c", (790, 288), (810, 310), (835, 320), (850, 340)),
        ("load", "blocks"): ("c", (780, 288), (806, 330), (806, 400), (800, 437)),
        ("world", "blocks"): [(863, 388), (840, 437)],
        ("render", "math"): [(440, 412), (440, 535)],
        ("world", "math"): [(800, 512), (800, 535)],
        ("extent3", "vec3"): [(740, 585), (800, 585)],
    }
    for route in routes.values():
        if route[0] == "c":
            f.curve_arrow(*route[1:], color=E, sw=1.5)
        else:
            f.arrow(route, color=E, sw=1.5)

    # The diagram must match the code: every require() has its arrow and vice versa.
    pack_of = {n: v[7] for n, v in nodes.items()}
    expected = set()
    for a, b in require_graph("10-final"):
        if pack_of.get(b) == "math" and pack_of.get(a) != "math":
            b = "math"
            a = pack_of.get(a) if pack_of.get(a) in ("render", "world") else a
        expected.add((a, b))
    if expected != set(routes):
        raise SystemExit(f"modules: схема не збігається з require(): "
                         f"бракує {sorted(expected - set(routes))}, зайві {sorted(set(routes) - expected)}")
    f.text(230, 655, "Стрілка до рамки src/math — модулі використовують vec3, mat4, extent3.",
           color=MUTED)
    f.save(out("modules"))


# ---------------------------------------------------------------- 11-testing

@diagram("11-testing", "testability")
def testability():
    f = Fig(880, 470, "Що й наскільки легко перевіряти автоматично")
    f.text(440, 30, "Що й наскільки легко перевіряти автоматично", size=MD, weight="bold",
           anchor="middle")
    bands = (("Чиста логіка, без LÖVE", "легко: luajit tests/run.lua", GREEN,
              ["vec3", "extent3", "mat4", "vox", "world", "blocks", "raycast", "camera", "mesher",
               "Game.chooseEdit", "Renderer.chunksTouching", "WorldLoader.fromVox"]),
             ("Код, що звертається до love.mouse / love.keyboard",
              "потрібна «підробка» LÖVE (fake_love)", ORANGE, ["input/mouse_keyboard", "input/init"]),
             ("Те, що бачить око", "лише запуск і перегляд\n(або порівняння скриншотів)", RED,
              ["шейдери", "UV і текстури", "MSAA", "відчуття від керування"]))
    y = 54
    for title, note, color, chips in bands:
        # Lay the chips out in rows so they don't overflow the band.
        rows, row, w = [], [], 0
        for chip in chips:
            cw = text_width(chip, SM, mono=True) + 22
            if w + cw > 820 and row:
                rows.append(row)
                row, w = [], 0
            row.append((chip, cw))
            w += cw + 10
        rows.append(row)
        nlines = note.count("\n") + 1
        top_h = 30 + 16 * nlines
        h = top_h + len(rows) * 42 + 8
        f.rect(20, y, 840, h, fill=FILL[color], stroke=color, sw=WIDE, rx=4)
        f.text(38, y + 28, title, size=MD, weight="bold", color=color)
        f.text(842, y + 28, note, style="italic", anchor="end")
        for r, row in enumerate(rows):
            x = 38
            cy = y + top_h + r * 42
            for chip, cw in row:
                f.rect(x, cy, cw, 32, fill="#ffffff", stroke=color, sw=THIN, rx=3)
                f.text(x + cw / 2, cy + 21, chip, mono=True, anchor="middle")
                x += cw + 10
        y += h + 14
    f.save(out("testability"))


def out(name):
    lesson = DIAGRAMS[name][0]
    return os.path.join(ROOT, lesson, "images", name + ".g.svg")


if __name__ == "__main__":
    names = sys.argv[1:] or list(DIAGRAMS)
    failed = []
    for n in names:
        try:
            DIAGRAMS[n][1]()
            print("ok  ", n)
        except SystemExit as e:
            failed.append(n)
            print("FAIL", e)
    sys.exit(1 if failed else 0)
