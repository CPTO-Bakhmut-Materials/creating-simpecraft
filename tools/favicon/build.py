#!/usr/bin/env python3
"""Generates the book's favicon: the game's grass block wearing a graduation cap
(mortarboard). Writes theme/favicon.svg and theme/favicon.png, which mdBook picks up
by these exact names (so they cannot follow the usual ".g." naming of generated files).

Usage: python3 tools/favicon/build.py   (needs rsvg-convert for the PNG)
"""

import os
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
THEME = os.path.join(ROOT, "theme")

# Colours from the game's textures (Kenney voxel pack) and the .vox reference colours.
GRASS_TOP, GRASS_LEFT, GRASS_RIGHT = "#5f9f35", "#4f8a2b", "#3f7322"
DIRT_LEFT, DIRT_RIGHT, DIRT_SPECK = "#8a6140", "#6e4c31", "#5a3d27"
# Navy rather than black, so the cap stays visible on dark browser tab bars too.
CAP, CAP_TOP, CAP_EDGE = "#24456b", "#2f5a8a", "#16304d"
TASSEL = "#f2b705"


def poly(points, fill, stroke=None, width=0.6):
    pts = " ".join(f"{x:g},{y:g}" for x, y in points)
    s = f' stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"' if stroke else ""
    return f'<polygon points="{pts}" fill="{fill}"{s}/>'


def svg():
    # Isometric block in a 32x32 box: top face, left face, right face.
    top = [(16, 11), (28, 17), (16, 23), (4, 17)]
    left = [(4, 17), (16, 23), (16, 31), (4, 25)]
    right = [(16, 23), (28, 17), (28, 25), (16, 31)]
    parts = [
        poly(left, DIRT_LEFT),
        poly(right, DIRT_RIGHT),
        # The grass overhang along the top edge of both sides.
        poly([(4, 17), (16, 23), (16, 26), (4, 20)], GRASS_LEFT),
        poly([(16, 23), (28, 17), (28, 20), (16, 26)], GRASS_RIGHT),
        poly(top, GRASS_TOP),
    ]
    # A few darker dirt specks, like the texture.
    for x, y in ((7, 23), (11, 26), (20, 27), (24, 24), (9, 21.5)):
        parts.append(f'<rect x="{x}" y="{y}" width="1.6" height="1.6" fill="{DIRT_SPECK}"/>')

    # Mortarboard sitting on the block: the skull cap, then the square board above it.
    parts.append(poly([(10, 12.5), (22, 12.5), (22, 15.5), (16, 18.5), (10, 15.5)], CAP))
    board = [(16, 3), (29, 9.5), (16, 16), (3, 9.5)]
    parts.append(poly(board, CAP_TOP, CAP_EDGE, 0.8))
    parts.append(f'<circle cx="16" cy="9.5" r="1.1" fill="{TASSEL}"/>')
    # The tassel: along the board to its right corner, then hanging down.
    parts.append(f'<path d="M16 9.5 L27.5 9.5 L27.5 16.5" fill="none" stroke="{TASSEL}"'
                 ' stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>')
    parts.append(poly([(26.3, 16), (28.7, 16), (29.2, 20), (25.8, 20)], TASSEL))

    body = "\n  ".join(parts)
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">\n'
            f"  {body}\n</svg>\n")


def main():
    path = os.path.join(THEME, "favicon.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg())
    png = os.path.join(THEME, "favicon.png")
    subprocess.run(["rsvg-convert", "-w", "64", "-h", "64", path, "-o", png], check=True)
    print("wrote", os.path.relpath(path, ROOT), "and", os.path.relpath(png, ROOT))


if __name__ == "__main__":
    main()
