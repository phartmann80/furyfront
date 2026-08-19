#!/usr/bin/env python3
"""Procedural 256px ship materials. Original, no third-party photos. CC0-style noise."""
from __future__ import annotations

import math
import os
import struct
import zlib


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "game", "assets", "v02", "mat")
SIZE = 256


def _chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: str, w: int, h: int, rgb: bytes) -> None:
    raw = b"".join(b"\x00" + rgb[i * w * 3 : (i + 1) * w * 3] for i in range(h))
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", zlib.compress(raw, 9)) + _chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


def hash2(x: int, y: int, s: int) -> float:
    n = (x * 374761393 + y * 668265263 + s * 1274126177) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177
    return ((n ^ (n >> 16)) & 0xFFFFFFFF) / 4294967295.0


def value_noise(x: float, y: float, seed: int) -> float:
    x0, y0 = int(math.floor(x)), int(math.floor(y))
    fx, fy = x - x0, y - y0
    fx = fx * fx * (3.0 - 2.0 * fx)
    fy = fy * fy * (3.0 - 2.0 * fy)
    v00 = hash2(x0, y0, seed)
    v10 = hash2(x0 + 1, y0, seed)
    v01 = hash2(x0, y0 + 1, seed)
    v11 = hash2(x0 + 1, y0 + 1, seed)
    return v00 * (1 - fx) * (1 - fy) + v10 * fx * (1 - fy) + v01 * (1 - fx) * fy + v11 * fx * fy


def fbm(x: float, y: float, seed: int, octaves: int = 4) -> float:
    a, f, t, n = 1.0, 1.0, 0.0, 0.0
    for i in range(octaves):
        t += a * value_noise(x * f, y * f, seed + i * 19)
        n += a
        a *= 0.5
        f *= 2.05
    return t / n


def clamp(v: float) -> int:
    return max(0, min(255, int(v)))


def mix(a: tuple[float, float, float], b: tuple[float, float, float], t: float) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return (
        clamp((a[0] + (b[0] - a[0]) * t) * 255.0),
        clamp((a[1] + (b[1] - a[1]) * t) * 255.0),
        clamp((a[2] + (b[2] - a[2]) * t) * 255.0),
    )


def gen(name: str, fn) -> None:
    buf = bytearray(SIZE * SIZE * 3)
    i = 0
    for y in range(SIZE):
        for x in range(SIZE):
            u, v = x / SIZE, y / SIZE
            r, g, b = fn(u, v, x, y)
            buf[i] = r
            buf[i + 1] = g
            buf[i + 2] = b
            i += 3
    path = os.path.join(OUT, name)
    write_png(path, SIZE, SIZE, bytes(buf))
    print(name, os.path.getsize(path))


def weave(u: float, v: float, x: int, y: int) -> tuple[int, int, int]:
    n = fbm(u * 8.0, v * 8.0, 11)
    thread = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(x * 0.85) * math.sin(y * 0.85))
    t = 0.35 + 0.45 * n + 0.20 * thread
    return mix((0.18, 0.20, 0.14), (0.38, 0.36, 0.28), t)


def grit(u: float, v: float, x: int, y: int) -> tuple[int, int, int]:
    n = fbm(u * 6.0, v * 6.0, 23)
    specks = hash2(x, y, 91)
    t = 0.40 + 0.50 * n + (0.08 if specks > 0.92 else 0.0)
    return mix((0.10, 0.11, 0.12), (0.28, 0.27, 0.24), t)


def leather(u: float, v: float, _x: int, _y: int) -> tuple[int, int, int]:
    n = fbm(u * 5.0, v * 5.0, 37)
    grain = fbm(u * 18.0, v * 18.0, 41)
    t = 0.30 + 0.50 * n + 0.20 * grain
    return mix((0.16, 0.10, 0.06), (0.42, 0.28, 0.16), t)


def visor(u: float, v: float, _x: int, _y: int) -> tuple[int, int, int]:
    streak = 0.5 + 0.5 * math.sin((u * 2.2 + v * 0.4) * math.pi * 2)
    n = fbm(u * 3.0, v * 3.0, 53)
    t = 0.25 + 0.40 * n + 0.35 * streak
    return mix((0.04, 0.06, 0.08), (0.18, 0.28, 0.32), t)


def polymer(u: float, v: float, x: int, y: int) -> tuple[int, int, int]:
    n = fbm(u * 7.0, v * 7.0, 67)
    fleck = hash2(x // 2, y // 2, 7)
    t = 0.45 + 0.40 * n + (0.10 if fleck > 0.88 else 0.0)
    return mix((0.05, 0.05, 0.06), (0.16, 0.16, 0.17), t)


def metal(u: float, v: float, x: int, y: int) -> tuple[int, int, int]:
    n = fbm(u * 4.5, v * 4.5, 79)
    mill = 0.5 + 0.5 * math.sin(y * 0.35 + n * 4.0)
    scratch = hash2(x, y // 3, 13)
    t = 0.35 + 0.35 * n + 0.22 * mill + (0.08 if scratch > 0.97 else 0.0)
    return mix((0.12, 0.13, 0.14), (0.38, 0.39, 0.40), t)


def main() -> None:
    gen("tex_weave.png", weave)
    gen("tex_grit.png", grit)
    gen("tex_leather.png", leather)
    gen("tex_visor.png", visor)
    gen("tex_poly.png", polymer)
    gen("tex_metal.png", metal)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
