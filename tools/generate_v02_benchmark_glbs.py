#!/usr/bin/env python3
"""Fury Front V0.2 V2 GLBs — local authored hard-surface. No Meshy."""
from __future__ import annotations

import json
import math
import struct
import zlib
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game" / "assets" / "v02"
TEX = 1024
SRC = 256


def _crc(tag: bytes, data: bytes) -> int:
    return zlib.crc32(tag + data) & 0xFFFFFFFF


def write_png(rgba: bytes, w: int, h: int) -> bytes:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", _crc(tag, data))

    raw = b"".join(b"\x00" + rgba[y * w * 4 : (y + 1) * w * 4] for y in range(h))
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b"")


def nrm_cross(a, b, c):
    e1 = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    e2 = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    nx = e1[1] * e2[2] - e1[2] * e2[1]
    ny = e1[2] * e2[0] - e1[0] * e2[2]
    nz = e1[0] * e2[1] - e1[1] * e2[0]
    ln = math.sqrt(nx * nx + ny * ny + nz * nz) or 1.0
    return (nx / ln, ny / ln, nz / ln)


def add3(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def mul3(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def basis_from(ax):
    ln = math.sqrt(ax[0] ** 2 + ax[1] ** 2 + ax[2] ** 2) or 1.0
    ax = (ax[0] / ln, ax[1] / ln, ax[2] / ln)
    if abs(ax[1]) < 0.92:
        rx = (-ax[2], 0.0, ax[0])
    else:
        rx = (1.0, 0.0, 0.0)
    rl = math.sqrt(rx[0] ** 2 + rx[1] ** 2 + rx[2] ** 2)
    rx = (rx[0] / rl, rx[1] / rl, rx[2] / rl)
    ux = (ax[1] * rx[2] - ax[2] * rx[1], ax[2] * rx[0] - ax[0] * rx[2], ax[0] * rx[1] - ax[1] * rx[0])
    return ax, rx, ux


def uv_island(mat: int, fu: float, fv: float) -> tuple[float, float]:
    ox = (mat % 2) * 0.5 + 0.01
    oy = (mat // 2) * 0.5 + 0.01
    return (ox + fu * 0.48, oy + fv * 0.48)


class Acc:
    def __init__(self) -> None:
        self.p: list[tuple] = []
        self.n: list[tuple] = []
        self.uv: list[tuple] = []
        self.i: list[int] = []
        self.tm: list[int] = []

    def tri(self, a, b, c, n=None, uva=(0, 0), uvb=(1, 0), uvc=(0, 1), mat=0) -> None:
        if n is None:
            n = nrm_cross(a, b, c)
        base = len(self.p)
        self.p.extend((a, b, c))
        self.n.extend((n, n, n))
        self.uv.extend((uv_island(mat, *uva), uv_island(mat, *uvb), uv_island(mat, *uvc)))
        self.i.extend((base, base + 1, base + 2))
        self.tm.append(mat)

    def quad(self, a, b, c, d, mat=0, n=None) -> None:
        if n is None:
            n = nrm_cross(a, b, c)
        self.tri(a, b, c, n, (0, 0), (1, 0), (1, 1), mat)
        self.tri(a, c, d, n, (0, 0), (1, 1), (0, 1), mat)

    def box(self, c, s, mat=0) -> None:
        hx, hy, hz = s[0] * 0.5, s[1] * 0.5, s[2] * 0.5
        x, y, z = c
        p = [
            (x - hx, y - hy, z - hz),
            (x + hx, y - hy, z - hz),
            (x + hx, y + hy, z - hz),
            (x - hx, y + hy, z - hz),
            (x - hx, y - hy, z + hz),
            (x + hx, y - hy, z + hz),
            (x + hx, y + hy, z + hz),
            (x - hx, y + hy, z + hz),
        ]
        for f in ((0, 1, 2, 3), (5, 4, 7, 6), (4, 0, 3, 7), (1, 5, 6, 2), (3, 2, 6, 7), (4, 5, 1, 0)):
            self.quad(p[f[0]], p[f[1]], p[f[2]], p[f[3]], mat)

    def chamfer_box(self, c, s, mat=0, b=0.008) -> None:
        x, y, z = c
        hx, hy, hz = s[0] * 0.5, s[1] * 0.5, s[2] * 0.5
        b = min(b, hx * 0.38, hy * 0.38, hz * 0.38)
        faces = {
            "+z": [
                (x - hx + b, y - hy + b, z + hz),
                (x + hx - b, y - hy + b, z + hz),
                (x + hx - b, y + hy - b, z + hz),
                (x - hx + b, y + hy - b, z + hz),
            ],
            "-z": [
                (x + hx - b, y - hy + b, z - hz),
                (x - hx + b, y - hy + b, z - hz),
                (x - hx + b, y + hy - b, z - hz),
                (x + hx - b, y + hy - b, z - hz),
            ],
            "+x": [
                (x + hx, y - hy + b, z - hz + b),
                (x + hx, y + hy - b, z - hz + b),
                (x + hx, y + hy - b, z + hz - b),
                (x + hx, y - hy + b, z + hz - b),
            ],
            "-x": [
                (x - hx, y + hy - b, z - hz + b),
                (x - hx, y - hy + b, z - hz + b),
                (x - hx, y - hy + b, z + hz - b),
                (x - hx, y + hy - b, z + hz - b),
            ],
            "+y": [
                (x - hx + b, y + hy, z - hz + b),
                (x - hx + b, y + hy, z + hz - b),
                (x + hx - b, y + hy, z + hz - b),
                (x + hx - b, y + hy, z - hz + b),
            ],
            "-y": [
                (x - hx + b, y - hy, z + hz - b),
                (x - hx + b, y - hy, z - hz + b),
                (x + hx - b, y - hy, z - hz + b),
                (x + hx - b, y - hy, z + hz - b),
            ],
        }
        for q in faces.values():
            self.quad(q[0], q[1], q[2], q[3], mat)
        edges = [
            (faces["+z"][1], faces["+x"][3], faces["+x"][2], faces["+z"][2]),
            (faces["+z"][3], faces["-x"][3], faces["-x"][2], faces["+z"][0]),
            (faces["+z"][2], faces["+y"][2], faces["+y"][1], faces["+z"][3]),
            (faces["+z"][0], faces["-y"][0], faces["-y"][3], faces["+z"][1]),
            (faces["-z"][1], faces["-x"][1], faces["-x"][0], faces["-z"][2]),
            (faces["-z"][0], faces["+x"][0], faces["+x"][1], faces["-z"][3]),
            (faces["-z"][2], faces["+y"][0], faces["+y"][3], faces["-z"][3]),
            (faces["-z"][1], faces["-y"][1], faces["-y"][2], faces["-z"][0]),
            (faces["+x"][2], faces["+y"][2], faces["+y"][3], faces["+x"][1]),
            (faces["+x"][0], faces["-y"][2], faces["-y"][3], faces["+x"][3]),
            (faces["-x"][2], faces["+y"][1], faces["+y"][0], faces["-x"][0]),
            (faces["-x"][1], faces["-y"][1], faces["-y"][0], faces["-x"][2]),
        ]
        for e in edges:
            self.quad(e[0], e[1], e[2], e[3], mat)

    def plate(self, c, s, mat=0, inset=0.014, bevel=0.006) -> None:
        self.chamfer_box(c, s, mat, bevel)
        ix = max(s[0] - inset * 2, s[0] * 0.62)
        iy = max(s[1] - inset * 2, s[1] * 0.62)
        iz = max(s[2] * 0.32, 0.005)
        self.chamfer_box((c[0], c[1], c[2] + s[2] * 0.28), (ix, iy, iz), mat, bevel * 0.6)

    def cyl(self, a, b, r0, r1=None, segs=28, stacks=8, cap=True, mat=0, smooth=True) -> None:
        if r1 is None:
            r1 = r0
        ax, rx, ux = basis_from((b[0] - a[0], b[1] - a[1], b[2] - a[2]))
        rings = []
        nrms = []
        for s in range(stacks + 1):
            t = s / stacks
            r = r0 * (1 - t) + r1 * t
            o = add3(a, mul3((b[0] - a[0], b[1] - a[1], b[2] - a[2]), t))
            ring = []
            ns = []
            for i in range(segs):
                ang = i / segs * math.tau
                ct, st = math.cos(ang), math.sin(ang)
                n = (rx[0] * ct + ux[0] * st, rx[1] * ct + ux[1] * st, rx[2] * ct + ux[2] * st)
                ring.append(add3(o, mul3(n, r)))
                ns.append(n)
            rings.append(ring)
            nrms.append(ns)
        for s in range(stacks):
            for i in range(segs):
                j = (i + 1) % segs
                a0, a1 = rings[s][i], rings[s][j]
                b0, b1 = rings[s + 1][i], rings[s + 1][j]
                if smooth:
                    self._smooth_quad(a0, a1, b1, b0, nrms[s][i], nrms[s][j], nrms[s + 1][j], nrms[s + 1][i], mat, i / segs, (i + 1) / segs, s / stacks, (s + 1) / stacks)
                else:
                    self.quad(a0, a1, b1, b0, mat)
        if cap:
            for i in range(segs):
                j = (i + 1) % segs
                self.tri(a, rings[0][j], rings[0][i], mat=mat)
                self.tri(b, rings[-1][i], rings[-1][j], mat=mat)

    def _smooth_quad(self, a, b, c, d, na, nb, nc, nd, mat, u0, u1, v0, v1) -> None:
        base = len(self.p)
        self.p.extend((a, b, c, a, c, d))
        self.n.extend((na, nb, nc, na, nc, nd))
        self.uv.extend(
            (
                uv_island(mat, u0, v0),
                uv_island(mat, u1, v0),
                uv_island(mat, u1, v1),
                uv_island(mat, u0, v0),
                uv_island(mat, u1, v1),
                uv_island(mat, u0, v1),
            )
        )
        self.i.extend(range(base, base + 6))
        self.tm.extend((mat, mat))

    def hemisphere(self, c, r, segs=24, rings=10, mat=0, up=(0, 1, 0)) -> None:
        ax, rx, ux = basis_from(up)
        prev = None
        for ring in range(rings + 1):
            th = ring / rings * (math.pi * 0.5)
            ringp = []
            for i in range(segs):
                ang = i / segs * math.tau
                n = add3(mul3(ax, math.cos(th)), add3(mul3(rx, math.cos(ang) * math.sin(th)), mul3(ux, math.sin(ang) * math.sin(th))))
                p = add3(c, mul3(n, r))
                ringp.append((p, n))
            if prev:
                for i in range(segs):
                    j = (i + 1) % segs
                    self._smooth_quad(prev[i][0], prev[j][0], ringp[j][0], ringp[i][0], prev[i][1], prev[j][1], ringp[j][1], ringp[i][1], mat, i / segs, (i + 1) / segs, (ring - 1) / rings, ring / rings)
            prev = ringp

    def tris(self) -> int:
        return len(self.i) // 3

    def verts(self) -> int:
        return len(self.p)


def paint_set(kind: str) -> dict[str, bytes]:
    cache = ROOT / "tools" / ".texcache" / f"v2_{kind}"
    cache.mkdir(parents=True, exist_ok=True)
    names = ("albedo", "normal", "orm")
    if all((cache / f"{n}.png").exists() for n in names):
        return {n: (cache / f"{n}.png").read_bytes() for n in names}
    h = [[0.0] * SRC for _ in range(SRC)]
    alb = bytearray(SRC * SRC * 4)
    for y in range(SRC):
        for x in range(SRC):
            panel = 0.05 if ((x // 14) + (y // 18)) % 2 == 0 else 0.0
            seam = 0.14 if (x % 28 < 2 or y % 36 < 2) else 0.0
            h[y][x] = panel + seam
            if kind == "assault":
                col = (52 + panel * 70, 50 + panel * 62, 46 + panel * 42)
            elif kind == "phantom":
                col = (24 + panel * 36, 30 + panel * 44, 36 + panel * 50)
            elif kind == "kf16":
                col = (44 + panel * 36, 46 + panel * 34, 50 + panel * 32)
            else:
                col = (32 + panel * 28, 30 + panel * 24, 26 + panel * 18)
            i = (y * SRC + x) * 4
            alb[i : i + 4] = bytes((int(min(255, col[0])), int(min(255, col[1])), int(min(255, col[2])), 255))
    nrm = bytearray(SRC * SRC * 4)
    orm = bytearray(SRC * SRC * 4)
    for y in range(SRC):
        for x in range(SRC):
            hl = h[y][x - 1] if x else h[y][x]
            hr = h[y][x + 1] if x < SRC - 1 else h[y][x]
            hu = h[y - 1][x] if y else h[y][x]
            hd = h[y + 1][x] if y < SRC - 1 else h[y][x]
            dx, dy = (hl - hr) * 4.2, (hu - hd) * 4.2
            nz = 1.0
            ln = math.sqrt(dx * dx + dy * dy + nz * nz)
            nx, ny = dx / ln, dy / ln
            i = (y * SRC + x) * 4
            nrm[i : i + 4] = bytes((int((nx * 0.5 + 0.5) * 255), int((ny * 0.5 + 0.5) * 255), int((nz * 0.5 + 0.5) * 255), 255))
            ao = int(max(0, min(255, 225 - seam * 380)))
            if kind in ("assault", "kf16"):
                rough, metal = 108, 148
            elif kind == "phantom":
                rough, metal = 88, 96
            else:
                rough, metal = 158, 28
            orm[i : i + 4] = bytes((ao, rough, metal, 255))

    def up(srcb: bytes) -> bytes:
        dst = bytearray(TEX * TEX * 4)
        for y in range(TEX):
            sy = y * SRC // TEX
            so = sy * SRC * 4
            do = y * TEX * 4
            for x in range(TEX):
                si = so + (x * SRC // TEX) * 4
                di = do + x * 4
                dst[di : di + 4] = srcb[si : si + 4]
        return write_png(bytes(dst), TEX, TEX)

    out = {"albedo": up(bytes(alb)), "normal": up(bytes(nrm)), "orm": up(bytes(orm))}
    for n, b in out.items():
        (cache / f"{n}.png").write_bytes(b)
    return out


def pad4(b: bytes) -> bytes:
    return b + b"\x00" * ((4 - (len(b) % 4)) % 4)


def build_glb(name: str, mesh: Acc, maps: dict, materials: list[dict], extras: dict) -> bytes:
    pos = b"".join(struct.pack("<fff", *v) for v in mesh.p)
    nrm = b"".join(struct.pack("<fff", *v) for v in mesh.n)
    uvs = b"".join(struct.pack("<ff", *v) for v in mesh.uv)
    by_mat: dict[int, list[int]] = {i: [] for i in range(len(materials))}
    for t, mat in enumerate(mesh.tm):
        if mat not in by_mat:
            by_mat[mat] = []
        by_mat[mat].extend(mesh.i[t * 3 : t * 3 + 3])
    use32 = len(mesh.p) > 65535
    icomp = 5125 if use32 else 5123
    ipack = "<I" if use32 else "<H"
    idx_blobs = []
    idx_raw = []
    for mi in range(len(materials)):
        idxs = by_mat.get(mi, [])
        raw = b"".join(struct.pack(ipack, x) for x in idxs) if idxs else b""
        idx_raw.append(raw)
        idx_blobs.append(pad4(raw))
    pngs = [maps["albedo"], maps["normal"], maps["orm"]]
    blobs = [pad4(pos), pad4(nrm), pad4(uvs)] + idx_blobs + [pad4(p) for p in pngs]
    raw_lens = [len(pos), len(nrm), len(uvs)] + [len(r) for r in idx_raw] + [len(p) for p in pngs]
    buf = b"".join(blobs)
    views = []
    off = 0
    n_idx = len(materials)
    for i, ln in enumerate(raw_lens):
        rec = {"buffer": 0, "byteOffset": off, "byteLength": max(ln, 1) if ln == 0 else ln}
        if ln == 0:
            rec["byteLength"] = 0
        if i < 3:
            rec["target"] = 34962
        elif i < 3 + n_idx:
            rec["target"] = 34963
        views.append(rec)
        off += len(blobs[i])
    xs, ys, zs = [p[0] for p in mesh.p], [p[1] for p in mesh.p], [p[2] for p in mesh.p]
    accessors = [
        {"bufferView": 0, "componentType": 5126, "count": len(mesh.p), "type": "VEC3", "min": [min(xs), min(ys), min(zs)], "max": [max(xs), max(ys), max(zs)]},
        {"bufferView": 1, "componentType": 5126, "count": len(mesh.n), "type": "VEC3"},
        {"bufferView": 2, "componentType": 5126, "count": len(mesh.uv), "type": "VEC2"},
    ]
    prims = []
    for mi in range(len(materials)):
        count = len(by_mat.get(mi, []))
        if count == 0:
            continue
        accessors.append({"bufferView": 3 + mi, "componentType": icomp, "count": count, "type": "SCALAR"})
        prims.append({"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": len(accessors) - 1, "material": mi})
    img_base = 3 + n_idx
    images = [
        {"mimeType": "image/png", "bufferView": img_base, "name": name + "_albedo"},
        {"mimeType": "image/png", "bufferView": img_base + 1, "name": name + "_normal"},
        {"mimeType": "image/png", "bufferView": img_base + 2, "name": name + "_orm"},
    ]
    textures = [{"sampler": 0, "source": i} for i in range(3)]
    mats = []
    for md in materials:
        m = {
            "name": md["name"],
            "pbrMetallicRoughness": {
                "baseColorFactor": md.get("color", [1, 1, 1, 1]),
                "baseColorTexture": {"index": 0},
                "metallicRoughnessTexture": {"index": 2},
                "metallicFactor": md.get("metallic", 1.0),
                "roughnessFactor": md.get("roughness", 1.0),
            },
            "normalTexture": {"index": 1, "scale": 1.0},
            "occlusionTexture": {"index": 2},
        }
        if md.get("emissive"):
            m["emissiveFactor"] = md["emissive"]
        mats.append(m)
    nodes = [{"name": name, "mesh": 0}]
    children = []
    for i, (aname, pos3) in enumerate(extras.get("attach", []) + extras.get("bones", [])):
        nodes.append({"name": aname, "translation": [float(pos3[0]), float(pos3[1]), float(pos3[2])]})
        children.append(i + 1)
    if children:
        nodes[0]["children"] = children
    gltf = {
        "asset": {"version": "2.0", "generator": "Fury Front V0.2 V2 local authoring"},
        "buffers": [{"byteLength": len(buf)}],
        "bufferViews": views,
        "accessors": accessors,
        "images": images,
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}],
        "textures": textures,
        "materials": mats,
        "meshes": [{"name": name, "primitives": prims}],
        "nodes": nodes,
        "scenes": [{"name": name, "nodes": [0]}],
        "scene": 0,
        "extras": {"rigging": "Named joint/attachment empties only. No skin weights. Static T-pose / viewmodel pose."},
    }
    js = pad4(json.dumps(gltf, separators=(",", ":")).encode("utf-8"))
    body = b"glTF" + struct.pack("<II", 2, 12 + 8 + len(js) + 8 + len(buf))
    body += struct.pack("<II", len(js), 0x4E4F534A) + js
    body += struct.pack("<II", len(buf), 0x004E4942) + buf
    return body


def hand(m: Acc, origin, side: float, mat_glove=0, segs=12) -> None:
    palm = origin
    m.chamfer_box(palm, (0.078, 0.032, 0.098), mat_glove, 0.004)
    m.chamfer_box((palm[0], palm[1] + 0.016, palm[2] - 0.008), (0.07, 0.01, 0.055), mat_glove, 0.003)
    for i, xoff in enumerate((-0.03, -0.01, 0.01, 0.03)):
        length = 0.048 - abs(i - 1.2) * 0.004
        base = add3(palm, (xoff, 0.004, -0.052))
        p1 = add3(base, (0.0, 0.0, -length * 0.38))
        p2 = add3(base, (0.0, 0.0, -length * 0.72))
        tip = add3(base, (0.0, 0.0, -length))
        r = 0.0095 - i * 0.0004
        m.cyl(base, p1, r, r * 0.95, segs, 3, True, mat_glove)
        m.cyl(p1, p2, r * 0.95, r * 0.82, segs, 3, True, mat_glove)
        m.cyl(p2, tip, r * 0.82, r * 0.62, segs, 3, True, mat_glove)
        m.chamfer_box(p1, (r * 2.1, r * 1.4, 0.01), mat_glove, 0.002)
    thumb_a = add3(palm, (0.04 * side, 0.012, -0.008))
    thumb_b = add3(thumb_a, (0.016 * side, 0.01, -0.022))
    thumb_c = add3(thumb_b, (0.01 * side, 0.006, -0.02))
    m.cyl(thumb_a, thumb_b, 0.011, 0.009, segs, 3, True, mat_glove)
    m.cyl(thumb_b, thumb_c, 0.009, 0.007, segs, 3, True, mat_glove)


def molle_row(m: Acc, c, count: int, mat: int, dx=0.028) -> None:
    for i in range(count):
        x = c[0] + (i - (count - 1) * 0.5) * dx
        m.chamfer_box((x, c[1], c[2]), (0.018, 0.01, 0.008), mat, 0.002)


def assault() -> tuple[Acc, list, list]:
    m = Acc()
    A, U, V = 0, 1, 2
    segs, stacks = 32, 12
    for sx in (-1.0, 1.0):
        m.chamfer_box((0.11 * sx, 0.048, 0.06), (0.13, 0.08, 0.28), A, 0.01)
        m.chamfer_box((0.11 * sx, 0.088, 0.1), (0.11, 0.04, 0.16), A, 0.006)
        m.chamfer_box((0.11 * sx, 0.018, 0.08), (0.125, 0.02, 0.24), A, 0.004)
        for t in range(4):
            m.box((0.11 * sx, 0.01, 0.0 + t * 0.055), (0.11, 0.012, 0.018), A)
        m.cyl((0.11 * sx, 0.12, 0.02), (0.11 * sx, 0.48, 0.01), 0.052, 0.048, segs, stacks, False, U)
        m.plate((0.11 * sx, 0.42, 0.075), (0.1, 0.15, 0.05), A)
        m.chamfer_box((0.11 * sx, 0.4, 0.095), (0.07, 0.08, 0.03), A, 0.004)
        m.cyl((0.11 * sx, 0.48, 0.01), (0.11 * sx, 0.92, 0.02), 0.068, 0.078, segs, stacks, False, U)
        m.plate((0.11 * sx, 0.7, 0.085), (0.12, 0.18, 0.05), A)
        m.chamfer_box((0.11 * sx, 0.62, 0.09), (0.08, 0.08, 0.04), A, 0.004)
    m.cyl((0.0, 0.92, 0.0), (0.0, 1.08, 0.0), 0.135, 0.148, segs, 5, False, U)
    m.chamfer_box((0.0, 1.02, 0.0), (0.36, 0.07, 0.18), A, 0.008)
    for x in (-0.14, -0.05, 0.05, 0.14):
        m.chamfer_box((x, 1.0, 0.12), (0.07, 0.06, 0.055), A, 0.004)
    m.chamfer_box((0.16, 1.0, 0.0), (0.06, 0.07, 0.08), A, 0.004)
    m.cyl((0.0, 1.08, 0.0), (0.0, 1.5, 0.02), 0.148, 0.158, segs, 10, False, U)
    m.plate((0.0, 1.32, 0.125), (0.34, 0.36, 0.07), A)
    m.plate((0.0, 1.24, 0.155), (0.22, 0.16, 0.04), A)
    molle_row(m, (0.0, 1.42, 0.165), 6, A)
    molle_row(m, (0.0, 1.38, 0.165), 6, A)
    m.plate((0.0, 1.34, -0.125), (0.3, 0.3, 0.06), A)
    m.plate((0.18, 1.34, 0.04), (0.085, 0.22, 0.16), A)
    m.plate((-0.18, 1.34, 0.04), (0.085, 0.22, 0.16), A)
    m.chamfer_box((0.0, 1.48, 0.08), (0.2, 0.06, 0.12), A, 0.005)
    for x in (-0.12, 0.0, 0.12):
        m.chamfer_box((x, 1.16, 0.19), (0.09, 0.13, 0.058), A, 0.004)
        m.chamfer_box((x, 1.225, 0.19), (0.09, 0.028, 0.058), A, 0.003)
        molle_row(m, (x, 1.1, 0.22), 2, A, 0.03)
    m.chamfer_box((0.22, 1.22, 0.08), (0.07, 0.15, 0.08), A, 0.004)
    m.chamfer_box((-0.21, 1.44, -0.02), (0.06, 0.15, 0.055), A, 0.003)
    m.cyl((-0.21, 1.52, -0.02), (-0.21, 1.76, -0.02), 0.009, 0.007, 12, 8, False, A)
    m.cyl((-0.21, 1.52, -0.02), (-0.12, 1.68, 0.04), 0.005, 0.004, 8, 6, False, A)
    m.plate((0.26, 1.5, 0.02), (0.15, 0.1, 0.17), A)
    m.plate((-0.26, 1.5, 0.02), (0.15, 0.1, 0.17), A)
    m.chamfer_box((0.26, 1.5, 0.08), (0.1, 0.06, 0.08), A, 0.004)
    m.chamfer_box((-0.26, 1.5, 0.08), (0.1, 0.06, 0.08), A, 0.004)
    for sx in (-1.0, 1.0):
        m.cyl((0.3 * sx, 1.48, 0.0), (0.72 * sx, 1.45, 0.02), 0.05, 0.044, segs, stacks, False, U)
        m.plate((0.5 * sx, 1.47, 0.045), (0.13, 0.07, 0.07), A)
        m.chamfer_box((0.62 * sx, 1.45, 0.03), (0.08, 0.055, 0.055), A, 0.004)
        m.cyl((0.72 * sx, 1.45, 0.02), (1.08 * sx, 1.42, 0.0), 0.04, 0.036, segs, stacks, False, U)
        m.chamfer_box((0.9 * sx, 1.435, 0.0), (0.09, 0.05, 0.05), A, 0.003)
        hand(m, (1.14 * sx, 1.41, 0.0), sx, A, 12)
    m.cyl((0.0, 1.5, 0.0), (0.0, 1.63, 0.0), 0.05, 0.046, 18, 5, False, U)
    m.chamfer_box((0.0, 1.56, 0.04), (0.12, 0.06, 0.08), A, 0.004)
    m.hemisphere((0.0, 1.72, 0.0), 0.132, 28, 10, A)
    m.cyl((0.0, 1.68, 0.0), (0.0, 1.75, 0.0), 0.128, 0.122, 28, 3, False, A)
    m.chamfer_box((0.0, 1.66, 0.04), (0.2, 0.05, 0.16), A, 0.005)
    m.chamfer_box((0.0, 1.685, 0.125), (0.18, 0.048, 0.032), A, 0.003)
    m.chamfer_box((0.0, 1.668, 0.145), (0.155, 0.028, 0.018), V, 0.002)
    m.chamfer_box((0.12, 1.69, 0.02), (0.05, 0.055, 0.08), A, 0.003)
    m.chamfer_box((-0.12, 1.69, 0.02), (0.05, 0.055, 0.08), A, 0.003)
    m.chamfer_box((0.0, 1.8, -0.01), (0.07, 0.035, 0.09), A, 0.003)
    m.cyl((0.0, 1.8, 0.04), (0.0, 1.86, 0.08), 0.012, 0.01, 12, 4, True, A)
    m.chamfer_box((0.0, 1.64, -0.08), (0.14, 0.05, 0.06), A, 0.003)
    bones = [
        ("Hips", (0.0, 1.02, 0.0)),
        ("Spine", (0.0, 1.18, 0.0)),
        ("Chest", (0.0, 1.36, 0.0)),
        ("Neck", (0.0, 1.56, 0.0)),
        ("Head", (0.0, 1.74, 0.0)),
        ("LeftShoulder", (-0.26, 1.5, 0.02)),
        ("RightShoulder", (0.26, 1.5, 0.02)),
        ("LeftUpperArm", (-0.5, 1.47, 0.0)),
        ("RightUpperArm", (0.5, 1.47, 0.0)),
        ("LeftLowerArm", (-0.9, 1.435, 0.0)),
        ("RightLowerArm", (0.9, 1.435, 0.0)),
        ("LeftHand", (-1.14, 1.41, 0.0)),
        ("RightHand", (1.14, 1.41, 0.0)),
        ("LeftUpLeg", (-0.11, 0.7, 0.0)),
        ("RightUpLeg", (0.11, 0.7, 0.0)),
        ("LeftLeg", (-0.11, 0.3, 0.01)),
        ("RightLeg", (0.11, 0.3, 0.01)),
        ("LeftFoot", (-0.11, 0.05, 0.06)),
        ("RightFoot", (0.11, 0.05, 0.06)),
    ]
    mats = [
        {"name": "armor", "metallic": 0.55, "roughness": 0.45, "color": [0.72, 0.68, 0.58, 1]},
        {"name": "undersuit", "metallic": 0.08, "roughness": 0.82, "color": [0.22, 0.23, 0.24, 1]},
        {"name": "visor", "metallic": 0.85, "roughness": 0.16, "emissive": [0.04, 0.035, 0.02], "color": [0.18, 0.16, 0.12, 1]},
    ]
    return m, bones, mats


def phantom() -> tuple[Acc, list, list]:
    m = Acc()
    A, U, V = 0, 1, 2
    segs, stacks = 30, 11
    for sx in (-1.0, 1.0):
        m.chamfer_box((0.09 * sx, 0.042, 0.045), (0.1, 0.065, 0.2), A, 0.006)
        m.cyl((0.09 * sx, 0.1, 0.01), (0.09 * sx, 0.46, 0.0), 0.04, 0.038, segs, stacks, False, U)
        m.chamfer_box((0.09 * sx, 0.4, 0.055), (0.07, 0.1, 0.035), A, 0.003)
        m.cyl((0.09 * sx, 0.46, 0.0), (0.09 * sx, 0.9, 0.015), 0.052, 0.058, segs, stacks, False, U)
        m.chamfer_box((0.09 * sx, 0.68, 0.065), (0.075, 0.12, 0.038), A, 0.003)
    m.cyl((0.0, 0.9, 0.0), (0.0, 1.06, 0.0), 0.105, 0.118, segs, 5, False, U)
    m.chamfer_box((0.0, 1.0, 0.0), (0.26, 0.055, 0.14), A, 0.006)
    m.cyl((0.0, 1.06, 0.0), (0.0, 1.46, 0.015), 0.118, 0.122, segs, 10, False, U)
    m.plate((0.0, 1.28, 0.105), (0.24, 0.3, 0.042), A)
    m.plate((0.0, 1.3, -0.125), (0.16, 0.24, 0.07), A)
    m.chamfer_box((0.0, 1.48, -0.16), (0.09, 0.07, 0.05), A, 0.003)
    m.cyl((0.0, 1.5, -0.16), (0.0, 1.74, -0.22), 0.011, 0.007, 12, 8, False, A)
    m.cyl((0.04, 1.48, -0.14), (0.08, 1.62, -0.1), 0.006, 0.005, 8, 5, False, V)
    for sx in (-1.0, 1.0):
        m.plate((0.17 * sx, 1.4, 0.0), (0.085, 0.08, 0.12), A)
        m.cyl((0.22 * sx, 1.4, 0.0), (0.58 * sx, 1.38, 0.02), 0.036, 0.032, segs, stacks, False, U)
        m.cyl((0.58 * sx, 1.38, 0.02), (0.94 * sx, 1.36, 0.0), 0.03, 0.026, segs, stacks, False, U)
        m.chamfer_box((0.76 * sx, 1.37, 0.01), (0.06, 0.04, 0.04), A, 0.002)
        hand(m, (1.0 * sx, 1.35, 0.0), sx, A, 11)
    m.cyl((0.0, 1.46, 0.0), (0.0, 1.58, 0.0), 0.04, 0.038, 16, 4, False, U)
    m.hemisphere((0.0, 1.64, 0.02), 0.108, 26, 9, A)
    m.chamfer_box((0.0, 1.61, 0.125), (0.16, 0.042, 0.028), A, 0.003)
    m.chamfer_box((0.0, 1.595, 0.142), (0.135, 0.022, 0.016), V, 0.002)
    m.chamfer_box((0.085, 1.64, 0.04), (0.038, 0.038, 0.05), A, 0.002)
    m.chamfer_box((-0.085, 1.64, 0.04), (0.038, 0.038, 0.05), A, 0.002)
    m.cyl((0.085, 1.64, 0.06), (0.085, 1.64, 0.09), 0.012, 0.01, 10, 3, True, V)
    m.chamfer_box((0.0, 1.22, 0.14), (0.08, 0.1, 0.04), A, 0.003)
    bones = [
        ("Hips", (0.0, 1.0, 0.0)),
        ("Spine", (0.0, 1.14, 0.0)),
        ("Chest", (0.0, 1.3, 0.0)),
        ("Neck", (0.0, 1.52, 0.0)),
        ("Head", (0.0, 1.64, 0.02)),
        ("LeftUpperArm", (-0.4, 1.39, 0.0)),
        ("RightUpperArm", (0.4, 1.39, 0.0)),
        ("LeftHand", (-1.0, 1.35, 0.0)),
        ("RightHand", (1.0, 1.35, 0.0)),
        ("LeftUpLeg", (-0.09, 0.68, 0.0)),
        ("RightUpLeg", (0.09, 0.68, 0.0)),
        ("LeftFoot", (-0.09, 0.04, 0.04)),
        ("RightFoot", (0.09, 0.04, 0.04)),
    ]
    mats = [
        {"name": "stealth_armor", "metallic": 0.42, "roughness": 0.34, "color": [0.28, 0.34, 0.4, 1]},
        {"name": "undersuit", "metallic": 0.06, "roughness": 0.78, "color": [0.12, 0.13, 0.14, 1]},
        {"name": "sensor", "metallic": 0.9, "roughness": 0.12, "emissive": [0.02, 0.09, 0.11], "color": [0.08, 0.22, 0.28, 1]},
    ]
    return m, bones, mats


def kf16() -> tuple[Acc, list, list]:
    m = Acc()
    MET, POL = 0, 1
    segs = 28
    m.chamfer_box((0.0, 0.02, 0.05), (0.05, 0.07, 0.26), MET, 0.004)
    m.chamfer_box((0.0, 0.042, 0.04), (0.038, 0.018, 0.22), MET, 0.002)
    m.chamfer_box((0.0, -0.012, 0.04), (0.046, 0.03, 0.18), MET, 0.003)
    for z in [i * 0.016 - 0.09 for i in range(18)]:
        m.chamfer_box((0.0, 0.056, z), (0.026, 0.009, 0.01), MET, 0.001)
    for z in [i * 0.02 - 0.26 for i in range(12)]:
        m.chamfer_box((0.024, 0.01, z), (0.008, 0.012, 0.012), MET, 0.001)
        m.chamfer_box((-0.024, 0.01, z), (0.008, 0.012, 0.012), MET, 0.001)
        m.chamfer_box((0.0, -0.012, z), (0.012, 0.008, 0.012), MET, 0.001)
    m.cyl((0.0, 0.028, -0.08), (0.0, 0.028, -0.54), 0.011, 0.01, segs, 16, False, MET)
    m.cyl((0.0, 0.028, -0.08), (0.0, 0.028, -0.54), 0.006, 0.005, 16, 8, False, MET)
    m.cyl((0.0, 0.042, -0.1), (0.0, 0.042, -0.34), 0.005, 0.0045, 12, 10, False, MET)
    m.chamfer_box((0.0, 0.012, -0.2), (0.048, 0.04, 0.22), MET, 0.003)
    m.chamfer_box((0.0, 0.034, -0.2), (0.018, 0.01, 0.2), MET, 0.001)
    for z in [i * 0.028 - 0.3 for i in range(8)]:
        m.chamfer_box((0.022, 0.012, z), (0.01, 0.018, 0.014), MET, 0.001)
        m.chamfer_box((-0.022, 0.012, z), (0.01, 0.018, 0.014), MET, 0.001)
    m.cyl((0.0, 0.028, -0.54), (0.0, 0.028, -0.64), 0.015, 0.0135, segs, 5, True, MET)
    for ang in range(8):
        t = ang / 8 * math.tau
        m.chamfer_box((math.cos(t) * 0.013, 0.028 + math.sin(t) * 0.013, -0.59), (0.007, 0.005, 0.032), MET, 0.001)
    m.cyl((0.0, 0.02, 0.18), (0.0, 0.02, 0.3), 0.016, 0.015, 16, 6, False, POL)
    for z in (0.2, 0.24, 0.28):
        m.cyl((0.0, 0.02, z - 0.01), (0.0, 0.02, z + 0.01), 0.018, 0.018, 16, 2, False, POL)
    m.chamfer_box((0.0, -0.005, 0.32), (0.032, 0.09, 0.038), POL, 0.004)
    m.chamfer_box((0.0, 0.03, 0.33), (0.042, 0.045, 0.02), POL, 0.003)
    m.chamfer_box((0.0, -0.09, 0.025), (0.028, 0.11, 0.045), POL, 0.004)
    m.chamfer_box((0.0, -0.04, 0.05), (0.034, 0.014, 0.072), MET, 0.002)
    m.chamfer_box((0.0, -0.028, 0.018), (0.008, 0.03, 0.014), MET, 0.001)
    m.chamfer_box((0.02, 0.0, 0.08), (0.01, 0.012, 0.02), MET, 0.001)
    m.chamfer_box((0.0, -0.105, -0.02), (0.026, 0.13, 0.05), POL, 0.003)
    m.chamfer_box((0.0, -0.175, -0.02), (0.028, 0.018, 0.052), POL, 0.002)
    for y in (-0.08, -0.11, -0.14):
        m.cyl((0.014, y, -0.02), (0.02, y, -0.02), 0.006, 0.006, 10, 2, True, POL)
    m.chamfer_box((0.0, 0.082, -0.05), (0.022, 0.04, 0.075), MET, 0.002)
    m.chamfer_box((0.0, 0.108, -0.05), (0.028, 0.014, 0.04), MET, 0.002)
    m.chamfer_box((0.0, 0.108, -0.05), (0.018, 0.01, 0.022), POL, 0.001)
    m.chamfer_box((0.034, 0.04, -0.015), (0.014, 0.022, 0.055), MET, 0.002)
    m.chamfer_box((0.042, 0.052, 0.085), (0.032, 0.012, 0.045), MET, 0.002)
    m.chamfer_box((0.0, 0.07, 0.12), (0.03, 0.025, 0.04), MET, 0.002)
    m.chamfer_box((0.0, 0.055, -0.4), (0.012, 0.03, 0.018), MET, 0.001)
    attach = [
        ("MuzzleFlash", (0.0, 0.028, -0.66)),
        ("ShellEject", (0.045, 0.045, -0.02)),
        ("Magazine", (0.0, -0.1, -0.02)),
        ("AdsAlign", (0.0, 0.09, -0.05)),
    ]
    mats = [
        {"name": "metal", "metallic": 0.88, "roughness": 0.3, "color": [0.55, 0.56, 0.58, 1]},
        {"name": "polymer", "metallic": 0.08, "roughness": 0.68, "color": [0.14, 0.13, 0.12, 1]},
    ]
    return m, attach, mats


def fps_arms() -> tuple[Acc, list, list]:
    m = Acc()
    G, S = 0, 1
    segs = 18
    m.cyl((0.24, -0.28, -0.02), (0.12, -0.18, -0.28), 0.04, 0.032, segs, 10, False, S)
    m.chamfer_box((0.22, -0.25, -0.08), (0.06, 0.052, 0.13), S, 0.006)
    m.chamfer_box((0.16, -0.21, -0.2), (0.055, 0.042, 0.07), G, 0.004)
    m.chamfer_box((0.14, -0.2, -0.24), (0.05, 0.028, 0.04), G, 0.003)
    hand(m, (0.08, -0.16, -0.36), 1.0, G, 14)
    m.cyl((-0.22, -0.26, -0.04), (-0.12, -0.16, -0.32), 0.038, 0.03, segs, 10, False, S)
    m.chamfer_box((-0.2, -0.23, -0.1), (0.055, 0.05, 0.12), S, 0.006)
    m.chamfer_box((-0.15, -0.18, -0.24), (0.048, 0.038, 0.055), G, 0.004)
    hand(m, (-0.1, -0.15, -0.4), -1.0, G, 14)
    bones = [
        ("LeftForearm", (-0.17, -0.21, -0.18)),
        ("LeftHand", (-0.1, -0.15, -0.4)),
        ("RightForearm", (0.18, -0.23, -0.16)),
        ("RightHand", (0.08, -0.16, -0.36)),
    ]
    mats = [
        {"name": "glove", "metallic": 0.12, "roughness": 0.72, "color": [0.16, 0.15, 0.13, 1]},
        {"name": "sleeve", "metallic": 0.05, "roughness": 0.8, "color": [0.28, 0.3, 0.26, 1]},
    ]
    return m, bones, mats


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    jobs = [
        ("ff_op_assault", "assault", assault, "bones"),
        ("ff_sb_phantom", "phantom", phantom, "bones"),
        ("ff_wpn_kf16", "kf16", kf16, "attach"),
        ("ff_fps_arms", "arms", fps_arms, "bones"),
    ]
    stats = []
    for asset_id, kind, builder, extra_key in jobs:
        mesh, extra, mats = builder()
        maps = paint_set(kind)
        extras = {extra_key: extra}
        glb = build_glb(asset_id, mesh, maps, mats, extras)
        path = OUT / f"{asset_id}.glb"
        path.write_bytes(glb)
        rec = {
            "asset_id": asset_id,
            "version": "v2",
            "generation_method": "Local authored GLB V2 (layered hard-surface, UV islands, albedo/normal/ORM). No Meshy.",
            "generation_date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "source_files": ["tools/generate_v02_benchmark_glbs.py"],
            "output_files": [str(path.relative_to(ROOT)).replace("\\", "/")],
            "triangle_count": mesh.tris(),
            "vertex_count": mesh.verts(),
            "material_count": len(mats),
            "texture_resolution": f"{TEX}x{TEX}",
            "pbr_maps": ["albedo", "normal", "orm"],
            "texture_memory_estimate_mb": round((TEX * TEX * 4 * 3) / (1024 * 1024), 2),
            "glb_bytes": path.stat().st_size,
            "licensing": "Original Fury Front work product.",
            "rigging": "Documented joint/attachment empties only. No skin weights. Static T-pose / viewmodel pose.",
        }
        stats.append(rec)
        print(f"{asset_id}: tris={mesh.tris()} verts={mesh.verts()} mats={len(mats)} bytes={path.stat().st_size}")
        lo, hi = {
            "ff_op_assault": (12000, 20000),
            "ff_sb_phantom": (10000, 18000),
            "ff_wpn_kf16": (5000, 8000),
            "ff_fps_arms": (2000, 5000),
        }[asset_id]
        if mesh.tris() < lo:
            print(f"  WARN below target {lo}-{hi}")
        if mesh.tris() > hi:
            print(f"  WARN above target {lo}-{hi}")
    (OUT / "generation_stats.json").write_text(json.dumps(stats, indent=2), encoding="utf-8")
    print("wrote", OUT / "generation_stats.json")


if __name__ == "__main__":
    main()
